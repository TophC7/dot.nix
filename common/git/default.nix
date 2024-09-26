{
    # !!! FOR HOME MANAGER Not nix config
    programs.git = {
        enable = true;
        userName = "[REDACTED]";
        userEmail = "36116606+TophC7@users.noreply.github.com";
        extraConfig = {
            init = {
                defaultBranch = "main";
            };
        };
    };
}