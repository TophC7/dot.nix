# Shared desktop Home Manager modules.
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.mix-nix.homeManagerModules.monitors ] ++ lib.fs.scanPaths ./home;
  
  # Common desktop packages
  home.packages = with pkgs; [
    android-tools
    scrcpy # android screen mirror
  ];
}
