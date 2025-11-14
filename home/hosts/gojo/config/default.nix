{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  monitors = [
    {
      name = "DP-1";
      primary = true;
      width = 2560;
      height = 1440;
      refreshRate = 359.979;
      x = 2560; # Left-most monitor
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
      hdr = true;
      vrr = true;
    }
    {
      name = "DP-3";
      width = 2560;
      height = 1440;
      refreshRate = 359.979;
      x = 1080;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
      hdr = true;
      vrr = true;
    }
  ];

  #   home.file.".config/monitors_source" = {
  #     source = ./monitors.xml;
  #     onChange = ''
  #       cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
  #     '';
  #   };
}
