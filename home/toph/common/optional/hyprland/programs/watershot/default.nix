{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.watershot.packages.${pkgs.system}.default
    pkgs.grim
  ];

  home.file.".config/watershot.ron" = {
    source = ./watershot.ron;
  };
}
