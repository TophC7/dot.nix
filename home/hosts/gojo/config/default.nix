{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  monitors = [
    {
      name = "DP-1";
      primary = true;
      width = 2560;
      height = 1440;
      refreshRate = 360;
      x = 2560;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
      # hdr = true;
      vrr = true;
    }
    {
      name = "DP-2";
      width = 2560; # Left-most monitor
      height = 1440;
      refreshRate = 360;
      x = 0;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
      # hdr = true;
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
