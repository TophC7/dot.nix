# Run with: fish hosts/nimbus/config/builds/tests/lock-publisher.fish
set -g helper (path resolve (status dirname)/../lock-publisher.fish)
set -g sandbox (mktemp -d)
or exit 1
function cleanup --on-event fish_exit
    rm -rf -- "$sandbox"
end
function check
    if not $argv
        echo "FAIL: $argv" >&2
        exit 1
    end
end
function publish
    fish "$helper" $argv "$sandbox/repo" "$sandbox/state"
end

check git init --quiet --bare "$sandbox/origin"
check git init --quiet --initial-branch=main "$sandbox/repo"
cd "$sandbox/repo"; or exit 1
check git config user.name "Host builder test"
check git config user.email "host-builder@example.invalid"
check git config commit.gpgSign false
check git config core.hooksPath "$sandbox/hooks"
check git remote add origin "$sandbox/origin"
printf 'base\n' >flake.lock
printf 'base\n' >tracked
check git add .
check git commit --quiet -m initial
check git push --quiet origin main

# Both staging layers and staged new files must survive a lock-only commit.
printf 'staged\n' >tracked
printf 'new\n' >added
printf 'manual staged lock\n' >flake.lock
check git add tracked added flake.lock
printf 'unstaged\n' >tracked
printf 'manual unstaged lock\n' >flake.lock
check publish prepare
printf 'nightly\n' >flake.lock
check publish capture
printf 'later staged lock\n' >flake.lock
check git add flake.lock
printf 'later unstaged lock\n' >flake.lock
check publish publish
check test (git show HEAD:flake.lock) = nightly
check test (git show :flake.lock) = 'later staged lock'
check test (string collect < flake.lock) = 'later unstaged lock'
check test (git show HEAD:tracked) = base
check test (git show :tracked) = staged
check test (string collect < tracked) = unstaged
check test (git show :added) = new
check test (git diff-tree --no-commit-id --name-only -r HEAD | string collect) = flake.lock
check test (git rev-parse HEAD) = (git --git-dir="$sandbox/origin" rev-parse refs/heads/main)

# Existing lock staging is eligible for publication, not left as a reversal.
check publish prepare
printf 'next nightly\n' >flake.lock
check publish capture
check publish publish
check git diff --quiet -- flake.lock
check git diff --cached --quiet -- flake.lock
check test (git show :tracked) = staged
check test (string collect < tracked) = unstaged

# No changed lock creates no empty commit.
set -l before (git rev-parse HEAD)
check publish prepare
check publish capture
check publish publish
check test (git rev-parse HEAD) = "$before"

# A rejected push leaves a retryable commit without consuming unrelated work.
mkdir -p "$sandbox/origin/hooks"
printf '#!%s\nexit 1\n' (command -s fish) >"$sandbox/origin/hooks/pre-receive"
chmod +x "$sandbox/origin/hooks/pre-receive"
check publish prepare
printf 'retry nightly\n' >flake.lock
check publish capture
if publish publish
    echo 'FAIL: rejected push reported success' >&2
    exit 1
end
set -l retry (git rev-parse HEAD)
check test "$retry" != "$before"
check test (git show :tracked) = staged
check test (string collect < tracked) = unstaged
rm "$sandbox/origin/hooks/pre-receive"
check publish prepare
check publish capture
check publish publish
check test (git rev-parse HEAD) = "$retry"
check test (git --git-dir="$sandbox/origin" rev-parse refs/heads/main) = "$retry"

# A user commit during the build must not be overwritten by publication.
check publish prepare
printf 'unpublished nightly\n' >flake.lock
check publish capture
check git -c core.hooksPath=/dev/null commit --quiet --allow-empty --only -m concurrent
set -l concurrent (git rev-parse HEAD)
if publish publish
    echo 'FAIL: concurrent history change was not rejected' >&2
    exit 1
end
check test (git rev-parse HEAD) = "$concurrent"
check test (string collect < flake.lock) = 'unpublished nightly'
check test (git show :tracked) = staged
check test (string collect < tracked) = unstaged
check test (git show :added) = new
check test ! -e .git/index.lock

echo 'PASS: captured lock publication, staged/unstaged preservation, push retry, history safety'
