# Fuzzel - Application launcher for Wayland
{ lib, pkgs, ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        width = 40;
        lines = 15;
        terminal = "${lib.getExe pkgs.ghostty}";
        layer = "overlay";
      };
      colors = {
        # Will be set by stylix
      };
    };
  };
}
