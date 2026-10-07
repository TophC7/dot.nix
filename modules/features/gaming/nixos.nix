{
  inputs,
  pkgs,
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
    steam = {
      enable = true;
      # GDK titles (Minecraft Dungeons II) need WineGDK's Gaming Services stand-in
      extraCompatPackages = [ pkgs.gdk-proton ];
    };
  };
}
