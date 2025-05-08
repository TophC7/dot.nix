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
    withUWSM = true;
  };

  environment.systemPackages = [
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
    inputs.better-control.packages.${pkgs.system}.better-control
  ];
}
