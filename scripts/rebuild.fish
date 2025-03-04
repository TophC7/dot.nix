#!/usr/bin/env fish

function red
    # Usage: red <message> [<command-string>]
    printf "\033[31m[!] %s \033[0m\n" $argv[1]
    if test (count $argv) -ge 2
        # If there's a second argument, we eval it and print in red as well
        printf "\033[31m[!] %s \033[0m\n" (eval "$argv[2]")
    end
end

function green
    # Usage: green <message> [<command-string>]
    printf "\033[32m[+] %s \033[0m\n" $argv[1]
    if test (count $argv) -ge 2
        printf "\033[32m[+] %s \033[0m\n" (eval "$argv[2]")
    end
end

function yellow
    # Usage: yellow <message> [<command-string>]
    printf "\033[33m[*] %s \033[0m\n" $argv[1]
    if test (count $argv) -ge 2
        printf "\033[33m[*] %s \033[0m\n" (eval "$argv[2]")
    end
end

# Build switch arguments
set switch_args "--show-trace" "--impure" "--flake"

# Check first argument
if test (count $argv) -gt 0 -a "$argv[1]" = "trace"
    set switch_args $switch_args "--show-trace"
else if test (count $argv) -gt 0
    set HOST $argv[1]
else
    set HOST (hostname)
end

# Append flake and host switch
set switch_args $switch_args ".#$HOST" "switch"

green "====== REBUILD ======"

# Check if `nh` exists
if type -q nh
    find ~ -type f -name "*.homeManagerBackupFileExtension" -delete
    set -x REPO_PATH (pwd)
    nh os switch . -- --impure --show-trace
else
    find ~ -type f -name "*.homeManagerBackupFileExtension" -delete
    sudo nixos-rebuild $switch_args
end

# If successful
if test $status -eq 0
    green "====== POST-REBUILD ======"
    green "Rebuilt successfully"

    # Check for a clean git working directory
    if git diff --exit-code >/dev/null
        and git diff --staged --exit-code >/dev/null
        # Check if the current HEAD commit is already tagged as buildable
        if git tag --points-at HEAD | grep -q buildable
            yellow "Current commit is already tagged as buildable"
        else
            git tag buildable-(date +%Y%m%d%H%M%S) -m ''
            green "Tagged current commit as buildable"
        end
    else
        yellow "WARN: There are pending changes that would affect the build succeeding. Commit them before tagging"
    end
end
