{
  pkgs,
  lib,
  ...
}:
{
  imports = lib.fs.scanPaths ./.;

  home.packages = with pkgs; [
    prismlauncher
    # stable.dolphin-emu-primehack
    cemu
    WiiUDownloader
    ukmm
  ];
}
