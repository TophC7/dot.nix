{
  pkgs,
  lib,
  inputs,
  config,
  secretsSpec,
  flakeRoot,
  ...
}:
{
  imports = lib.flatten [
    ## Common Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/chromium.nix"
      "modules/home/common/claude.nix"
      "modules/home/common/gaming"
      "modules/home/common/vscode.nix"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])

    ## Rune Specific ##
    ./config
  ];

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Media ##
    ffmpeg_8-full
    spotify

    ## Social ##
    telegram-desktop
    vesktop

    ## Tools ##
    bitwarden-desktop
    inspector
    solaar
    vial # KB setup

    ## Development ##
    gh
  ];
}
