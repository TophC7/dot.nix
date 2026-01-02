{
  host,
  lib,
  inputs,
  ...
}:
{
  imports = lib.flatten [
    inputs.mix-nix.homeManagerModules.monitors
    (lib.optional (host.desktop.gnome.enable or false) ./_gnome)
    (lib.optional (host.desktop.hyprland.enable or false) ./_hyprland)
    (lib.optional (host.desktop.niri.enable or false) ./_niri)
  ];
}
