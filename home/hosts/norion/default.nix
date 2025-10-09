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
      "home/global/common/vscode"
      "home/global/common/xdg.nix"
      "home/global/common/zen.nix"
    ])

    ## Rune Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Media ##
    ffmpeg
    spotify

    ## Social ##
    telegram-desktop
    discord-krisp
    betterdiscordctl

    ## Tools ##
    bitwarden-desktop
    inspector
    solaar
    vial # KB setup
  ];
}
