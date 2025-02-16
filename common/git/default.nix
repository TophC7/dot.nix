{
    # !!! FOR HOME MANAGER Not nix config
    programs.git = {
        enable = true;
        userName = "[REDACTED]";
        userEmail = "[REDACTED]";
        extraConfig = {
            init = {
                defaultBranch = "main";
            };
        };
    };
}