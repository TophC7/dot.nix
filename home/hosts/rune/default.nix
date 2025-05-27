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
      "home/global/common/browsers"
      "home/global/common/gnome"
      "home/global/common/development"
      "home/global/common/gaming"
      "home/global/common/xdg.nix"
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
      vial # KB setup

      ## Productivity ##
      gimp
      inkscape
      ;
  };
}
