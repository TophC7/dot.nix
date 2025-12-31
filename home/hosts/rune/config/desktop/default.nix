{
  host,
  lib,
  inputs,
  ...
}:
{
  imports = lib.flatten [
    inputs.mix-nix.homeManagerModules.monitors
    (lib.optional (host.desktop == "gnome") ./gnome)
    (lib.optional (host.desktop == "hyprland") ./hyprland)
    (lib.optional (host.desktop == "niri") ./niri)
  ];
}
