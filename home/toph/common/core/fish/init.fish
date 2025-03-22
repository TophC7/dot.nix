function cd
    zoxide $argv
end

function garbage
    sudo nh clean
    nh clean
    sudo nix-collect-garbage --delete-old
    nix-collect-garbage --delete-old
    sudo nix-store --gc
    nix-store --gc
end

function ls
    eza $argv
end

function rebuild
    if test -f ~/git/Nix/dot.nix/scripts/rebuild.fish
        cd ~/git/Nix/dot.nix
        scripts/rebuild.fish
    else
        echo (set_color yellow)" - Rebuild not found"(set_color normal)
    end
end

function s
    ssh (whoami)@$argv
end

set fish_greeting # Disable greeting

fastfetch
