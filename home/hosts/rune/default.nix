{
  pkgs,
  lib,
  inputs,
  config,
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

    ## Rune Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Media ##
      ffmpeg
      spotify
      gpu-screen-recorder-gtk

      ## Social ##
      telegram-desktop
      discord
      betterdiscordctl

      ## Tools ##
      bitwarden-desktop
      inspector
      remmina
      solaar
      vial # KB setup

      ## Productivity ##
      gimp
      inkscape
      ;

    inherit (pkgs.jetbrains)
      ## Development ##
      idea-ultimate
      ;
  };
}
