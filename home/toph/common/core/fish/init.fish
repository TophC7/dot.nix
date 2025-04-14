function cd
    zoxide $argv
end

# Clears all possible garbage from the Nix store 😀
function garbage
    sudo nh clean all
    nh clean all
    sudo nix-collect-garbage --delete-old
    nix-collect-garbage --delete-old
    sudo nix-store --gc
    nix-store --gc
end

function ls
    eza $argv
end

# Rebuilds the NixOS configuration, located in ~/git/Nix/dot.nix for all my hosts
function rebuild
    if test -f ~/git/Nix/dot.nix/scripts/rebuild.fish
        cd ~/git/Nix/dot.nix
        scripts/rebuild.fish
    else
        echo (set_color yellow)" - Rebuild not found"(set_color normal)
    end
end

# Discourage using rm command
function rm
    if test (count $argv) -gt 0
        echo "Error: 'rm' is protected. Please use 'trashy' command instead."
    end
end

# SSH function, just for convenience since I use it a lot
function s
    set user (whoami)
    set keyfile ""
    set host ""

    set args $argv
    while test (count $args) -gt 0
        switch $args[1]
            case -u
                if test (count $args) -ge 2
                    set user $args[2]
                    set args $args[3..-1]
                else
                    echo "Error: Option -u requires a username argument."
                    echo "Usage: s [-u username] [-i keyfile] host"
                    return 1
                end
            case -i
                if test (count $args) -ge 2
                    set keyfile $args[2]
                    set args $args[3..-1]
                else
                    echo "Error: Option -i requires a keyfile argument."
                    echo "Usage: s [-u username] [-i keyfile] host"
                    return 1
                end
            case '*'
                set host $args[1]
                set args $args[2..-1]
        end
    end

    if test -z "$host"
        echo "Error: Missing host."
        echo "Usage: s [-u username] [-i keyfile] host"
        return 1
    end

    if test -n "$keyfile"
        ssh -i $keyfile $user@$host
    else
        ssh $user@$host
    end
end

set fish_greeting # Disable greeting

fastfetch
