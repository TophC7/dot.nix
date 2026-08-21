# Common desktop Home Manager stack.
{ host, inputs, ... }:
let
  niriShells = {
    dms = ./dms;
    pana = ./pana;
  };

  desktops = {
    gnome = [
      ./gnome.nix
      ./shared
    ];
    niri = [
      niriShells.${host.niriShell}
      ./niri
      ./shared
    ];
  };
in
{
  imports = [ inputs.mix-nix.homeManagerModules.monitors ] ++ desktops.${host.desktop};
}
