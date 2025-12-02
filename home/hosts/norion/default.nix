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
      "home/global/common/chromium.nix"
      "home/global/common/claude.nix"
      "home/global/common/gaming"
      "home/global/common/vscode.nix"
      "home/global/common/xdg.nix"
      "home/global/common/zen.nix"
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
