function log
    echo (date '+%Y-%m-%d %H:%M:%S') '[host-builder]' $argv
end

function notify --argument-names body
    printf '%s' "$body" | apprise "$HOST_BUILD_NOTIFY_URL"
    or log 'Failed to send notification (non-critical)' >&2
end

function fail
    log $argv >&2
    notify "## ❌ host-builder Error
> "(string join ' ' -- $argv)
    exit 1
end

function section --argument-names label
    set -q argv[2]; or return 0
    set -a -g report_lines "> $label"
    for item in $argv[2..]
        set -a -g report_lines "> • $item"
    end
    return 0
end

function report --argument-names heading
    set -g report_lines "## $heading"
    section '✅ **Cached:**' $cached_hosts
    section '♻️ **Unchanged:**' $unchanged_hosts
    section '❌ **Failed:**' $failed_hosts
    section '⏭️ **Skipped:**' $skipped_hosts
    section '⚠️ **Dirty Inputs Skipped:**' $skipped_dirty_inputs
    set -a report_lines ">"
    if set -q published_locks[1]
        set -a report_lines "> 📝 Locks: "(string join ' · ' -- $published_locks)
    else
        set -a report_lines '> 📝 Locks: not published'
    end
    notify (string join \n $report_lines | string collect)
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
# Re-exec this exact interpreter with --no-config: a plain `fish` child sources
# /etc/fish/nixos-env-preinit.fish, which replaces PATH with the system
# environment and loses every binary the unit put on the path.
if not set -q HOST_BUILD_LOCKED
    set -gx HOST_BUILD_LOCKED 1
    flock --nonblock --conflict-exit-code 75 "$HOST_BUILD_STATE/build-hosts.lock" \
        (status fish-path) --no-config (status filename) $argv
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
        set -a -g unchanged_hosts $host
    else
        # Keep both outputs rooted while rotating. Nix registers these fixed
        # out-links as GC roots; unchanged runs never evict a distinct generation.
        if test -n "$current_output"
            nix build --out-link "$previous_root" "$current_output" >/dev/null; or return 1
        end
        nix build --out-link "$current_root" "$new_output" >/dev/null; or return 1
        log "Cached: $host"
        set -a -g cached_hosts $host
    end
    rm -f -- "$temporary_root"
end

# Publish, then report whether the branch actually advanced, so a run that only
# rebuilt hosts is distinguishable from one that moved a lock.
function publish_lock --argument-names label repo state_dir
    set -l before (git -C "$repo" rev-parse --short HEAD); or return 1
    lock-publisher publish "$repo" "$state_dir"; or return 1
    set -l after (git -C "$repo" rev-parse --short HEAD); or return 1
    # `set` passes the previous command's status through, so it must never be
    # the last statement of a function whose caller checks success.
    if test "$before" = "$after"
        set after unchanged
    end
    set -a -g published_locks "$label $after"
    return 0
end

function update_flake_lock --argument-names repo
    set -l lock_file "$repo/flake.lock"
    if not test -f "$lock_file"
        log "Updating all inputs for $repo (no flake.lock found)"
        nix flake update --flake "$repo"; or return 1
        return 0
    end

    set -l inputs_tsv (jq -r '
      . as $top
      | .nodes.root.inputs
      | to_entries[]
      | .key as $name
      | (if (.value | type) == "string" then .value else null end) as $node_name
      | if $node_name then
          $top.nodes[$node_name] as $node
          | [
              $name,
              ($node.original.type // ""),
              ($node.original.url // ""),
              ($node.original.path // "")
            ] | @tsv
        else
          empty
        end
    ' "$lock_file" 2>/dev/null); or return 1

    set -l to_update
    for line in $inputs_tsv
        set -l parts (string split \t -- "$line")
        set -l name $parts[1]
        set -l url $parts[3]
        set -l path $parts[4]

        set -l local_path "$path"
        if test -z "$local_path"
            if string match -q "file://*" -- "$url"
                set local_path (string replace -r "^file://" "" -- "$url" | string replace -r '\?.*$' "")
            else if string match -q "git+file://*" -- "$url"
                set local_path (string replace -r '^git\+file://' "" -- "$url" | string replace -r '\?.*$' "")
            end
        end

        if test -n "$local_path" -a -d "$local_path"
            set -l dirty (git -C "$local_path" status --porcelain 2>/dev/null)
            if test -n "$dirty"
                log "Skipping dirty local input: $name ($local_path)"
                set -a -g skipped_dirty_inputs "$name"
                continue
            end
        end

        set -a to_update $name
    end

    if test (count $to_update) -eq 0
        log "No clean inputs to update for $repo"
        return 0
    end

    log "Updating "(count $to_update)" inputs in $repo"
    nix flake update --flake "$repo" $to_update; or return 1
    return 0
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
update_flake_lock "$HOST_BUILD_MIX_REPO"
or fail 'Failed to update mix.nix flake lock'
lock-publisher capture "$HOST_BUILD_MIX_REPO" "$HOST_BUILD_STATE/locks/mix"
or fail 'Failed to capture mix.nix flake lock'
publish_lock mix.nix "$HOST_BUILD_MIX_REPO" "$HOST_BUILD_STATE/locks/mix"
or fail 'Failed to publish mix.nix flake lock'

log 'Updating dot.nix flake lock'
update_flake_lock "$HOST_BUILD_DOT_REPO"
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

set -g failed_hosts
set -g supported_hosts
set -l excluded (string split -n ' ' -- "$HOST_BUILD_SKIP")
for entry in $host_entries
    set -l fields (string split \t -- "$entry")
    if contains -- $fields[1] $excluded
        log "Skipping $fields[1] (excluded)"
        set -a -g skipped_hosts "$fields[1] (excluded)"
    else if test "$fields[2]" != "$HOST_BUILD_SYSTEM"
        log "Skipping $fields[1] ($fields[2]; builder is $HOST_BUILD_SYSTEM)"
        set -a -g skipped_hosts "$fields[1] ($fields[2])"
    else
        set -a supported_hosts $fields[1]
    end
end

if test (count $supported_hosts) -eq 0
    fail "No NixOS hosts support $HOST_BUILD_SYSTEM"
end

for host in $supported_hosts
    cache_host "$host"; or begin
        log "Build or cache-root update failed: $host" >&2
        set -a failed_hosts $host
    end
end

if test (count $failed_hosts) -gt 0
    log "dot.nix lock not published. Failed hosts: "(string join ', ' -- $failed_hosts) >&2
    report '❌ host-builder Failed'
    exit 1
end

log 'Publishing captured dot.nix flake lock'
publish_lock dot.nix "$HOST_BUILD_DOT_REPO" "$HOST_BUILD_STATE/locks/dot"
or fail 'Failed to publish dot.nix flake lock'

report '🔨 host-builder Complete'
log 'Host cache build completed'
