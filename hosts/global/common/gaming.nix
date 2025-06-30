{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.play.nixosModules.play
  ];

  play = {
    amd.enable = true;
    ananicy.enable = true;
    gamemode.enable = true;

    steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    lutris.enable = true;
  };

  # Additional packages not covered by play.nix
  environment.systemPackages = with pkgs; [
    heroic
  ];
}
