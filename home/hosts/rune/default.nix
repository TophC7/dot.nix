{
  flakeRoot,
  lib,
  host,
  pkgs,
  inputs,
  ...
}:
{
  imports = lib.flatten [
    ## Rune Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/chromium.nix"
      "modules/home/common/agents"
      "modules/home/common/affinity.nix"
      "modules/home/common/gaming"
      "modules/home/common/vscode.nix"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  services.easyeffects = {
    enable = true;
  };

  programs.ghostty = {
    settings = {
      adjust-cell-height = 1;
    };
  };

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    # inputs.hytale-launcher.packages.${host.system}.default

    ## Media ##
    ffmpeg_8-full
    spotify
    gpu-screen-recorder-gtk
    vlc
    v4l-utils

    ## Social ##
    telegram-desktop
    vesktop
    journey

    ## Tools ##
    bitwarden-desktop
    inspector
    remmina
    solaar
    vial # KB setup

    #proton
    proton-pass
    proton-authenticator

    # Web Dev
    gh
    vivaldi
    inputs.sworm.packages.${host.system}.default
  ];
}
