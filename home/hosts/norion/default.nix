{
  pkgs,
  lib,
  inputs,
  config,
  secretsSpec,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map lib.custom.relativeToRoot [
      "home/global/common/claude.nix"
      "home/global/common/gnome"
      "home/global/common/vscode"
      "home/global/common/xdg.nix"
      "home/global/common/zen.nix"
    ])

    ## Rune Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Tools ##
    bitwarden-desktop
    inspector
    solaar
    vial # KB setup
  ];
}
