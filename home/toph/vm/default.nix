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
    ../common/optional/desktops
    # ../common/optional/development
    # ../common/optional/gaming
    ../common/optional/xdg.nix # file associations
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Tools ##
      inspector
      wezterm
      ;
  };
}
