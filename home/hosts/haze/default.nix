{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "home/global/common/gaming"
      "home/global/common/gnome"
      "home/global/common/vscode"
      "home/global/common/xdg.nix"
      "home/global/common/zen.nix"
    ])

    ## Haze Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Media ##
      cider # Apple Music

      ## Tools ##
      inspector
      ;
  };
}
