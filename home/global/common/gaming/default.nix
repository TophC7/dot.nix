{
  pkgs,
  lib,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.packages = with pkgs; [
    prismlauncher
    # stable.dolphin-emu-primehack
    cemu
    wiiu-downloader
    ukmm
  ];
}
