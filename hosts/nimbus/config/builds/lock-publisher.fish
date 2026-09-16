function fail
    echo "lock-publisher: $argv" >&2
    return 1
end

function read_required --argument-names path
    if not test -s "$path"
        fail "missing state: $path"
        return 1
    end

    string collect <"$path"
end

function write_state --argument-names path value
    printf '%s\n' "$value" >"$path"
end

function repository_root --argument-names repo
    set -l root (git -C "$repo" rev-parse --show-toplevel 2>/dev/null); or begin
        fail "not a Git worktree: $repo"
        return 1
    end
    realpath -- "$root"
end

function current_position --argument-names repo expected_branch expected_head
    set -l branch (git -C "$repo" symbolic-ref --quiet HEAD 2>/dev/null); or begin
        fail "detached HEAD in $repo"
        return 1
    end
    set -l head (git -C "$repo" rev-parse --verify 'HEAD^{commit}' 2>/dev/null); or begin
        fail "invalid HEAD in $repo"
        return 1
    end

    if test "$branch" != "$expected_branch" -o "$head" != "$expected_head"
        fail "branch or HEAD changed in $repo"
        return 1
    end
end

function safe_git_state --argument-names repo
    set -l conflicts (git -C "$repo" ls-files --unmerged); or begin
        fail "cannot inspect index in $repo"
        return 1
    end
    if test (count $conflicts) -ne 0
        fail "unmerged index entries in $repo"
        return 1
    end

    for marker in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD REBASE_HEAD rebase-apply rebase-merge sequencer BISECT_START
        set -l path (git -C "$repo" rev-parse --path-format=absolute --git-path "$marker" 2>/dev/null); or return 1
        if test -e "$path"
            fail "Git operation in progress in $repo ($marker)"
            return 1
        end
    end

    set -l index (git -C "$repo" rev-parse --path-format=absolute --git-path index 2>/dev/null); or return 1
    if test -e "$index.lock"
        fail "Git index is locked in $repo"
        return 1
    end
end

function load_prepared_state --argument-names repo state_dir
    if not test -s "$state_dir/prepared"
        fail "prepare has not completed for $state_dir"
        return 1
    end

    set -g lock_publisher_repo (read_required "$state_dir/repo"); or return 1
    set -g lock_publisher_branch (read_required "$state_dir/branch"); or return 1
    set -g lock_publisher_head (read_required "$state_dir/head"); or return 1
    set -g lock_publisher_initial_entry (read_required "$state_dir/initial-index-entry"); or return 1
    set -g lock_publisher_mode (read_required "$state_dir/mode"); or return 1
    set -g lock_publisher_index (read_required "$state_dir/index"); or return 1

    set -l root (repository_root "$repo"); or return 1
    if test "$root" != "$lock_publisher_repo"
        fail "state belongs to another repository: $state_dir"
        return 1
    end
end

function prepare --argument-names repo state_dir
    set -l root (repository_root "$repo"); or return 1
    safe_git_state "$root"; or return 1

    set -l branch (git -C "$root" symbolic-ref --quiet HEAD 2>/dev/null); or begin
        fail "detached HEAD in $root"
        return 1
    end
    if not string match --quiet 'refs/heads/*' "$branch"
        fail "HEAD does not name a local branch in $root"
        return 1
    end

    set -l head (git -C "$root" rev-parse --verify 'HEAD^{commit}' 2>/dev/null); or begin
        fail "invalid HEAD in $root"
        return 1
    end
    set -l entry (git -C "$root" ls-files --stage -- flake.lock); or return 1
    if test (count $entry) -gt 1
        fail "flake.lock has multiple index entries in $root"
        return 1
    end

    set -l mode
    if test (count $entry) -eq 1
        if not string match --regex --quiet '^100(644|755) [0-9a-f]{40,64} 0\tflake\.lock$' "$entry"
            fail "flake.lock is not an ordinary index entry in $root"
            return 1
        end
        set mode (string replace --regex '^([0-7]{6}) .*' '$1' "$entry")
    else
        set entry absent
        set -l head_entry (git -C "$root" ls-tree "$head" -- flake.lock); or return 1
        if test (count $head_entry) -eq 1
            if not string match --regex --quiet '^100(644|755) blob [0-9a-f]{40,64}\tflake\.lock$' "$head_entry"
                fail "flake.lock is not an ordinary file in prepared HEAD"
                return 1
            end
            set mode (string replace --regex '^([0-7]{6}) .*' '$1' "$head_entry")
        else
            set mode 100644
        end
    end
    set -l index (git -C "$root" rev-parse --path-format=absolute --git-path index 2>/dev/null); or return 1
    current_position "$root" "$branch" "$head"; or return 1

    # The marker is written last: interruption can leave data files, never a
    # prepared transaction that capture or publish could mistake for complete.
    mkdir -p -- "$state_dir"; or return 1
    rm -f -- "$state_dir/prepared" "$state_dir/captured" "$state_dir/captured.lock" "$state_dir/captured-blob"
    write_state "$state_dir/repo" "$root"; or return 1
    write_state "$state_dir/branch" "$branch"; or return 1
    write_state "$state_dir/head" "$head"; or return 1
    write_state "$state_dir/initial-index-entry" "$entry"; or return 1
    write_state "$state_dir/mode" "$mode"; or return 1
    write_state "$state_dir/index" "$index"; or return 1
    write_state "$state_dir/prepared" 1
end

function capture --argument-names repo state_dir
    load_prepared_state "$repo" "$state_dir"; or return 1
    safe_git_state "$lock_publisher_repo"; or return 1
    current_position "$lock_publisher_repo" "$lock_publisher_branch" "$lock_publisher_head"; or return 1

    if not test -f "$lock_publisher_repo/flake.lock"
        fail "flake.lock is missing in $lock_publisher_repo"
        return 1
    end

    rm -f -- "$state_dir/captured"
    set -l temporary (mktemp "$state_dir/captured.lock.XXXXXX"); or return 1
    cp -- "$lock_publisher_repo/flake.lock" "$temporary"; or begin
        rm -f -- "$temporary"
        return 1
    end

    # Capture owns this copy. Later checkout edits are deliberately irrelevant
    # to the commit and must remain visible to the user after publication.
    set -l blob (git -C "$lock_publisher_repo" hash-object -w -- "$temporary"); or begin
        rm -f -- "$temporary"
        return 1
    end
    current_position "$lock_publisher_repo" "$lock_publisher_branch" "$lock_publisher_head"; or begin
        rm -f -- "$temporary"
        return 1
    end

    mv -f -- "$temporary" "$state_dir/captured.lock"; or return 1
    write_state "$state_dir/captured-blob" "$blob"; or return 1
    write_state "$state_dir/captured" 1
end

set -g lock_publisher_owned_index_lock
set -g lock_publisher_temporary_directory

function cleanup_publish
    if test -n "$lock_publisher_owned_index_lock"
        rm -f -- "$lock_publisher_owned_index_lock"
        set -g lock_publisher_owned_index_lock
    end
    if test -n "$lock_publisher_temporary_directory"
        rm -rf -- "$lock_publisher_temporary_directory"
        set -g lock_publisher_temporary_directory
    end
end

function cleanup_publish_on_exit --on-event fish_exit
    cleanup_publish
end

function publish --argument-names repo state_dir
    load_prepared_state "$repo" "$state_dir"; or return 1
    if not test -s "$state_dir/captured" -a -f "$state_dir/captured.lock"
        fail "capture has not completed for $state_dir"
        return 1
    end
    set -l recorded_blob (read_required "$state_dir/captured-blob"); or return 1
    set -l captured_blob (git -C "$lock_publisher_repo" hash-object -- "$state_dir/captured.lock"); or return 1
    if test "$captured_blob" != "$recorded_blob"
        fail "captured flake.lock changed in $state_dir"
        return 1
    end

    safe_git_state "$lock_publisher_repo"; or return 1
    current_position "$lock_publisher_repo" "$lock_publisher_branch" "$lock_publisher_head"; or return 1
    set -l current_index (git -C "$lock_publisher_repo" rev-parse --path-format=absolute --git-path index 2>/dev/null); or return 1
    if test "$current_index" != "$lock_publisher_index"
        fail "Git index path changed in $lock_publisher_repo"
        return 1
    end

    # Build the proposed tree in an isolated index. Only captured flake.lock is
    # overlaid on prepared HEAD, so unrelated staged or worktree files cannot
    # leak into the commit.
    set -g lock_publisher_temporary_directory (mktemp -d "$state_dir/publish.XXXXXX"); or return 1
    set -l proposed_index "$lock_publisher_temporary_directory/proposed-index"
    env GIT_INDEX_FILE="$proposed_index" git -C "$lock_publisher_repo" read-tree "$lock_publisher_head"; or return 1
    git -C "$lock_publisher_repo" hash-object -w -- "$state_dir/captured.lock" >/dev/null; or return 1
    env GIT_INDEX_FILE="$proposed_index" git -C "$lock_publisher_repo" update-index --add --cacheinfo "$lock_publisher_mode,$captured_blob,flake.lock"; or return 1
    set -l tree (env GIT_INDEX_FILE="$proposed_index" git -C "$lock_publisher_repo" write-tree); or return 1
    set -l parent_tree (git -C "$lock_publisher_repo" rev-parse "$lock_publisher_head^{tree}"); or return 1

    set -l published_head "$lock_publisher_head"
    if test "$tree" != "$parent_tree"
        set published_head (printf '%s\n' 'chore(nix): update flake.lock' | git -C "$lock_publisher_repo" commit-tree "$tree" -p "$lock_publisher_head"); or return 1
    end

    # Git's index.lock serializes the read/compare/write below with normal Git
    # commands. Ref update uses prepared HEAD as compare-and-swap. The ref moves
    # before index replacement: a crash can leave a harmless staged reverse
    # diff, but can never discard index data or overwrite newer branch history.
    set -l seed (mktemp "$lock_publisher_index.lock.XXXXXX"); or return 1
    if not ln -- "$seed" "$lock_publisher_index.lock"
        rm -f -- "$seed"
        fail "Git index is locked in $lock_publisher_repo"
        return 1
    end
    rm -f -- "$seed"
    set -g lock_publisher_owned_index_lock "$lock_publisher_index.lock"

    set -l real_index "$lock_publisher_temporary_directory/real-index"
    cp -- "$lock_publisher_index" "$real_index"; or return 1
    set -l conflicts (env GIT_INDEX_FILE="$real_index" git -C "$lock_publisher_repo" ls-files --unmerged); or return 1
    if test (count $conflicts) -ne 0
        fail "unmerged index entries appeared in $lock_publisher_repo"
        return 1
    end

    current_position "$lock_publisher_repo" "$lock_publisher_branch" "$lock_publisher_head"; or return 1

    set -l current_entry (env GIT_INDEX_FILE="$real_index" git -C "$lock_publisher_repo" ls-files --stage -- flake.lock); or return 1
    if test (count $current_entry) -eq 0
        set current_entry absent
    end

    set -l consume_initial 0
    if test (count $current_entry) -eq 1; and test "$current_entry" = "$lock_publisher_initial_entry"
        set consume_initial 1
        env GIT_INDEX_FILE="$real_index" git -C "$lock_publisher_repo" update-index --add --cacheinfo "$lock_publisher_mode,$captured_blob,flake.lock"; or return 1
    end

    if test "$published_head" != "$lock_publisher_head"
        git -C "$lock_publisher_repo" update-ref "$lock_publisher_branch" "$published_head" "$lock_publisher_head"; or begin
            fail "branch changed while publishing $lock_publisher_repo"
            return 1
        end
    end

    if test $consume_initial -eq 1
        # Copy across filesystems without ever unlinking the held index.lock.
        cp -- "$real_index" "$lock_publisher_owned_index_lock"; or return 1
        mv -f -- "$lock_publisher_owned_index_lock" "$lock_publisher_index"; or return 1
        set -g lock_publisher_owned_index_lock
    else
        rm -f -- "$lock_publisher_owned_index_lock"
        set -g lock_publisher_owned_index_lock
    end

    cleanup_publish

    current_position "$lock_publisher_repo" "$lock_publisher_branch" "$published_head"; or return 1

    # Exact object source plus a normal (non-force) push prevents local or
    # remote branch races from replacing history. A no-op still pushes prepared
    # HEAD, retrying a commit left local by an earlier failed push.
    git -C "$lock_publisher_repo" push origin "$published_head:$lock_publisher_branch"
end

if test (count $argv) -ne 3
    fail 'usage: lock-publisher prepare|capture|publish REPO STATE_DIR'
    exit 2
end

switch $argv[1]
    case prepare
        prepare "$argv[2]" "$argv[3]"; or exit 1
    case capture
        capture "$argv[2]" "$argv[3]"; or exit 1
    case publish
        publish "$argv[2]" "$argv[3]"; or exit 1
    case '*'
        fail "unknown command: $argv[1]"
        exit 2
end
