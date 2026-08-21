# Common desktop host stack.
{ host, ... }:
let
  niriShells = {
    dms = [ ];
    pana = [ ./pana.nix ];
  };

  desktops = {
    gnome = [ ./gnome.nix ];
    niri = [
      # Keep the production DMS greeter until Pana's greeter is ready.
      ./dms.nix
      ./niri.nix
    ]
    ++ niriShells.${host.niriShell};
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
