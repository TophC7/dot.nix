# Common desktop host stack.
{ host, lib, ... }:
let
  shellModules = {
    dms = ./dms;
    pana = ./pana;
  };

  desktops = {
    gnome = [
      ./gnome
      ./shared
    ];
    niri = [
      # Keep the production DMS greeter until Pana's greeter is ready.
      ./dms-greeter
      shellModules.${host.niriShell}
      ./niri
      ./shared
    ];
  };
in
{
  imports = lib.features (
    [
      "audio"
      "ddcutil"
      ./nautilus
    ]
    ++ desktops.${host.desktop}
  );
}
