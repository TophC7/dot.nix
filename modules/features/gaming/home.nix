{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = lib.fs.scanPaths ./home ++ [ inputs.play.homeManagerModules.play ];

  # Links Steam's Proton builds into Heroic under stable names
  play.heroic.enable = true;

  home.packages = with pkgs; [
    prismlauncher
    # stable.dolphin-emu-primehack
    # cemu
    # WiiUDownloader
    ukmm
    r2modman
  ];
}
