{
  lib,
  host,
  pkgs,
  inputs,
  ...
}:
{
  ## Rune Specific Imports ##
  imports = lib.fs.scanPaths ./.;

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
    inputs.bedrock-on-linux.packages.${host.system}.default

    ## Media ##
    ffmpeg_8-full
    spotify
    gpu-screen-recorder-gtk
    moonlight-qt
    vlc
    v4l-utils

    ## Social ##
    telegram-desktop
    vesktop
    journey

    ## Tools ##
    remmina
    solaar
    vial # KB setup

    # Web Dev
    gh
    gh-dash
    vivaldi
  ];
}
