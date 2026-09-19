# Run with: fish hosts/nimbus/config/builds/tests/update-lock.fish
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

function log
    # Quiet logger for tests
    return 0
end

# Extract update_flake_lock from build-hosts.fish
set -l builder (path resolve (status dirname)/../build-hosts.fish)
source (printf '%s\n' \
    "function log; return 0; end" \
    (sed -n '/^function update_flake_lock/,/^end/p' "$builder") \
    | psub)

# 1. Setup clean upstream sub-flake
check git init --quiet -b main "$sandbox/clean_sub"
check git -C "$sandbox/clean_sub" commit --allow-empty --quiet -m "init"
printf '{\n  outputs = { self }: { value = 1; };\n}\n' > "$sandbox/clean_sub/flake.nix"
check git -C "$sandbox/clean_sub" add flake.nix
check git -C "$sandbox/clean_sub" commit --quiet -m "flake clean 1"

# 2. Setup dirty upstream sub-flake
check git init --quiet -b main "$sandbox/dirty_sub"
check git -C "$sandbox/dirty_sub" commit --allow-empty --quiet -m "init"
printf '{\n  outputs = { self }: { value = 1; };\n}\n' > "$sandbox/dirty_sub/flake.nix"
check git -C "$sandbox/dirty_sub" add flake.nix
check git -C "$sandbox/dirty_sub" commit --quiet -m "flake dirty 1"

# 3. Setup root flake tracking both
check git init --quiet -b main "$sandbox/root"
printf '{\n  inputs.clean_sub.url = "git+file://%s/clean_sub";\n  inputs.dirty_sub.url = "git+file://%s/dirty_sub";\n  outputs = { self, clean_sub, dirty_sub }: { };\n}\n' \
    "$sandbox" "$sandbox" > "$sandbox/root/flake.nix"
check git -C "$sandbox/root" add flake.nix
check git -C "$sandbox/root" commit --quiet -m "init"

# 4. Lock both initially
check nix flake lock "$sandbox/root"
set -l initial_clean_rev (jq -r .nodes.clean_sub.locked.rev "$sandbox/root/flake.lock")
set -l initial_dirty_rev (jq -r .nodes.dirty_sub.locked.rev "$sandbox/root/flake.lock")

# 5. Commit an update to clean_sub
printf '{\n  outputs = { self }: { value = 2; };\n}\n' > "$sandbox/clean_sub/flake.nix"
check git -C "$sandbox/clean_sub" commit --quiet -am "flake clean 2"

# 6. Make dirty_sub dirty with broken syntax that would crash nix flake update
printf 'syntax error !!' > "$sandbox/dirty_sub/flake.nix"

# 7. Run update_flake_lock on root
check update_flake_lock "$sandbox/root"

# 8. Verify clean_sub updated, dirty_sub remained locked at old rev
set -l updated_clean_rev (jq -r .nodes.clean_sub.locked.rev "$sandbox/root/flake.lock")
set -l updated_dirty_rev (jq -r .nodes.dirty_sub.locked.rev "$sandbox/root/flake.lock")

check test "$updated_clean_rev" != "$initial_clean_rev"
check test "$updated_dirty_rev" = "$initial_dirty_rev"
check test "$skipped_dirty_inputs" = "dirty_sub"

echo "PASS: update-lock"
