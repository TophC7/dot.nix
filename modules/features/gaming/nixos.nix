{
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
    heroic.enable = true;
    steam.enable = true;
  };
}
