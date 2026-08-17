# Common desktop Home Manager stack.
{ host, inputs, ... }:
let
  desktops = {
    gnome = [
      ./gnome.nix
      ./shared
    ];
    niri = [
      ./dms
      ./niri
      ./shared
    ];
  };
in
{
  imports = [ inputs.mix-nix.homeManagerModules.monitors ] ++ desktops.${host.desktop};
}
