#!/usr/bin/env fish
#
# Rebuild with Discord notification via systemd-run
#

set -l host (hostname)
set -l unit_name rebuild-notify

for arg in $argv
    switch $arg
        case --status
            systemctl status $unit_name.service
            exit $status
        case --log
            journalctl -u $unit_name.service -f
            exit 0
        case --stop
            sudo systemctl stop $unit_name.service 2>/dev/null
            sudo systemctl reset-failed $unit_name.service 2>/dev/null
            echo Stopped
            exit 0
        case '*'
            set host $arg
    end
end

if test -z "$BONK_DISCORD_WEBHOOK"
    echo "Error: Set BONK_DISCORD_WEBHOOK env var"
    exit 1
end

set -l build_script /tmp/rebuild-$host.fish

printf '%s\n' '#!/usr/bin/env fish
set host "'$host'"
set apprise_url "'$BONK_DISCORD_WEBHOOK'?avatar=no&footer=no"

function notify
    printf "%s" $argv[1] | nix run nixpkgs#apprise -- -vv $apprise_url 2>/dev/null
    or true
end

echo "Starting rebuild for $host"
notify "## 🔨 Rebuild Started
> **Host:** $host"

set start_time (date +%s)

sudo nixos-rebuild switch --flake /repo/Nix/dot.nix#$host --option substituters "https://cache.nixos.org"
set exit_code $status

set duration (math (date +%s) - $start_time)
set mins (math "floor($duration / 60)")
set secs (math "$duration % 60")

if test $exit_code -eq 0
    notify "## ✅ Rebuild Complete
> **Host:** $host
> **Time:** "$mins"m "$secs"s"
else
    notify "## ❌ Rebuild Failed
> **Host:** $host
> **Exit:** $exit_code"
end
exit $exit_code
' >$build_script

chmod +x $build_script

# Force cleanup any existing unit
sudo systemctl stop $unit_name.service 2>/dev/null
sudo systemctl reset-failed $unit_name.service 2>/dev/null

echo "Starting rebuild for $host..."

sudo systemd-run \
    --no-block \
    --unit=$unit_name \
    --uid=toph \
    --gid=ryot \
    --setenv=PATH=/run/current-system/sw/bin \
    --setenv=HOME=/home/toph \
    /run/current-system/sw/bin/fish $build_script

if test $status -eq 0
    echo "✓ Started. ./rebuild-notify.fish --log to follow"
else
    echo "✗ Failed to start"
    exit 1
end
