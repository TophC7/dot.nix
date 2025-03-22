{
  inputs,
  pkgs,
  lib,
  ...
}:
{

  imports = lib.custom.scanPaths ./.;

  programs.hyprland = {
    enable = true;
    # withUWSM = true; # One day, but not today
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  environment.systemPackages = [
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
  ];
}
