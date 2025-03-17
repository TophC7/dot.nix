function s
    ssh (whoami)@$argv
end

function garbage
    sudo nh clean
    nh clean
    sudo nix-collect-garbage --delete-old
    nix-collect-garbage --delete-old
    sudo nix-store --gc
    nix-store --gc
end

set fish_greeting # Disable greeting

fastfetch
