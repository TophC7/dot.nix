# Shared desktop Home Manager modules.
{ lib, pkgs, ... }:
{
  imports = lib.fs.scanPaths ./.;
  
  # Common desktop packages
  home.packages = with pkgs; [
    android-tools
    scrcpy
  ];
}
