{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  # xdg.desktopEntries = {
  # };

  monitors = [
    {
      name = "eDP-1";
      primary = true;
      width = 1920;
      height = 1200;
      refreshRate = 60;
      x = 0;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
      hdr = false;
      vrr = false;
    }
  ];

  home.file.".config/monitors_source" = {
    source = ./monitors.xml;
    onChange = ''
      cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
      chmod 755 $HOME/.config/monitors.xml
    '';
  };
}
