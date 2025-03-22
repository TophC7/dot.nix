{
  pkgs,
  ...
}:
{
  imports = [
    ## Required Configs ##
    ../common/core # required

    ## Host-specific Optional Configs ##
    ../common/optional/browsers
    # ../common/optional/gnome
    ../common/optional/hyprland
    ../common/optional/development
    # ../common/optional/gaming
    ../common/optional/vscode-server.nix
    ../common/optional/xdg.nix # file associations
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Tools ##
      inspector
      foot
      ;
  };

  monitors = [
    {
      name = "Virtual-1";
      width = 2560;
      height = 1440;
      refreshRate = 60;
      primary = true;
    }
  ];
}
