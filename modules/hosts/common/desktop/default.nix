# Common desktop host stack.
{ host, ... }:
let
  desktops = {
    gnome = [ ./gnome.nix ];
    niri = [
      ./dms.nix
      ./niri.nix
    ];
  };
in
{
  imports = [
    ../audio.nix
    ../ddcutil.nix
    ./nautilus.nix
  ]
  ++ desktops.${host.desktop};
}
