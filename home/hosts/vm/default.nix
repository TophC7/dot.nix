{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "home/global/common/browsers"
      "home/global/common/gnome"
      "home/global/common/development"
      "home/global/common/vscode-server.nix"
      "home/global/common/xdg.nix"
    ])

    ## VM Specific ##
    # ./config
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
