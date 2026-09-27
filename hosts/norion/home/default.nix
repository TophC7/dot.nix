{
  pkgs,
  lib,
  ...
}:
{
  ## Norion Specific ##
  imports = lib.fs.scanPaths ./.;

  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    ## Media ##
    ffmpeg_8-full
    spotify

    ## Social ##
    telegram-desktop
    vesktop

    ## Tools ##
    solaar

    ## Development ##
    gh
  ];
}
