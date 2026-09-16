function log
    echo (date '+%Y-%m-%d %H:%M:%S') '[host-builder]' $argv
end

function fail
    log $argv >&2
    printf '%s' "Host cache build failed: "(string join ' ' -- $argv) | apprise "$HOST_BUILD_NOTIFY_URL"
    or log 'Failed to send notification (non-critical)' >&2
    exit 1
end

for variable in HOST_BUILD_STATE HOST_BUILD_SYSTEM HOST_BUILD_NOTIFY_URL HOST_BUILD_MIX_REPO HOST_BUILD_DOT_REPO
    if not set -q $variable; or test -z "$$variable"
        fail "$variable is required"
    end
end
if not string match -q '/*' -- "$HOST_BUILD_STATE"; or test "$HOST_BUILD_STATE" = /
    fail 'HOST_BUILD_STATE must be an absolute directory other than /'
end

mkdir -p "$HOST_BUILD_STATE"; or fail "Cannot create state directory $HOST_BUILD_STATE"

# systemd serializes the service; flock also covers manual script invocations.
if not set -q HOST_BUILD_LOCKED
    set -gx HOST_BUILD_LOCKED 1
    flock --nonblock --conflict-exit-code 75 "$HOST_BUILD_STATE/build-hosts.lock" fish (status filename) $argv
    set -l result $status
    if test $result -eq 75
        fail 'Another host cache build is already running'
    end
    exit $result
end

set -g temporary_roots "$HOST_BUILD_STATE/temporary-roots"
function remove_temporary_roots --on-event fish_exit
    rm -rf -- "$temporary_roots"
end

function cache_host --argument-names host
    set -l root_dir "$HOST_BUILD_STATE/roots/$host"
    set -l temporary_root "$temporary_roots/$host"
    set -l current_root "$root_dir/current"
    set -l previous_root "$root_dir/previous"
    mkdir -p "$root_dir"; or return 1

    log "Building $host ($HOST_BUILD_SYSTEM)"
    nix build --impure --max-jobs 1 --cores 10 -L --out-link "$temporary_root" \
        "$HOST_BUILD_DOT_REPO#nixosConfigurations.$host.config.system.build.toplevel"
    or return 1

    set -l new_output (readlink -f -- "$temporary_root"); or return 1
    test -n "$new_output"; or return 1
    set -l current_output
    if test -L "$current_root"
        set current_output (readlink -f -- "$current_root"); or return 1
        test -n "$current_output"; or return 1
    else if test -e "$current_root"
        log "Current root is not a symlink for $host" >&2
        return 1
    end

    if test "$new_output" = "$current_output"
        log "Unchanged: $host"
    else
        # Keep both outputs rooted while rotating. Nix registers these fixed
        # out-links as GC roots; unchanged runs never evict a distinct generation.
        if test -n "$current_output"
            nix build --out-link "$previous_root" "$current_output" >/dev/null; or return 1
        end
        nix build --out-link "$current_root" "$new_output" >/dev/null; or return 1
        log "Cached: $host"
    end
    rm -f -- "$temporary_root"
end

rm -rf -- "$temporary_roots"; or fail 'Cannot remove stale temporary roots'
mkdir -p "$temporary_roots" "$HOST_BUILD_STATE/roots" "$HOST_BUILD_STATE/locks/mix" "$HOST_BUILD_STATE/locks/dot"
or fail 'Cannot initialize host builder state'

# Prepare both repositories before updating either; never pull or stage files.
log 'Preparing repository lock state'
lock-publisher prepare "$HOST_BUILD_MIX_REPO" "$HOST_BUILD_STATE/locks/mix"
or fail 'Failed to prepare mix.nix lock publication'
lock-publisher prepare "$HOST_BUILD_DOT_REPO" "$HOST_BUILD_STATE/locks/dot"
or fail 'Failed to prepare dot.nix lock publication'

log 'Updating mix.nix flake lock'
nix flake update --flake "$HOST_BUILD_MIX_REPO"
or fail 'Failed to update mix.nix flake lock'
lock-publisher capture "$HOST_BUILD_MIX_REPO" "$HOST_BUILD_STATE/locks/mix"
or fail 'Failed to capture mix.nix flake lock'
lock-publisher publish "$HOST_BUILD_MIX_REPO" "$HOST_BUILD_STATE/locks/mix"
or fail 'Failed to publish mix.nix flake lock'

log 'Updating dot.nix flake lock'
nix flake update --flake "$HOST_BUILD_DOT_REPO"
or fail 'Failed to update dot.nix flake lock'
lock-publisher capture "$HOST_BUILD_DOT_REPO" "$HOST_BUILD_STATE/locks/dot"
or fail 'Failed to capture dot.nix flake lock'

# Separate evaluation from JSON parsing so jq cannot hide a Nix failure.
log 'Enumerating NixOS hosts'
set -l systems_json (nix eval --impure --json "$HOST_BUILD_DOT_REPO#nixosConfigurations" \
    --apply 'cfgs: builtins.mapAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system) cfgs')
or fail 'Failed to enumerate NixOS host systems'
set -l host_entries (printf '%s\n' "$systems_json" | jq -r 'to_entries | sort_by(.key)[] | [.key, .value] | @tsv')
or fail 'Failed to parse NixOS host systems'

set -l failed_hosts
set -l supported_hosts
for entry in $host_entries
    set -l fields (string split \t -- "$entry")
    set -l host $fields[1]
    set -l system $fields[2]
    if test "$system" != "$HOST_BUILD_SYSTEM"
        log "Skipping $host ($system; builder is $HOST_BUILD_SYSTEM)"
        continue
    end
    set -a supported_hosts $host
    cache_host "$host"; or begin
        log "Build or cache-root update failed: $host" >&2
        set -a failed_hosts $host
    end
end

if test (count $failed_hosts) -gt 0
    fail "dot.nix lock not published. Failed hosts: "(string join ', ' -- $failed_hosts)
end
if test (count $supported_hosts) -eq 0
    fail "No NixOS hosts support $HOST_BUILD_SYSTEM"
end

log 'Publishing captured dot.nix flake lock'
lock-publisher publish "$HOST_BUILD_DOT_REPO" "$HOST_BUILD_STATE/locks/dot"
or fail 'Failed to publish dot.nix flake lock'
log 'Host cache build completed'
