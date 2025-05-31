{
  lib,
  pkgs,
  hostSpec,
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

    ## Gojo Specific ##
    ./config
  ];

  home.sessionVariables = {
    FLAKE = "${hostSpec.home}/git/dot.nix";
  };

  ## Packages with no needed configs ##
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ## Media ##
      ffmpeg
      gpu-screen-recorder-gtk
      spotify
      youtube-music

      ## Social ##
      betterdiscordctl
      discord
      telegram-desktop

      ## Tools ##
      bitwarden-desktop
      inspector

      ## Productivity ##
      gimp
      inkscape
      ;
  };
}
