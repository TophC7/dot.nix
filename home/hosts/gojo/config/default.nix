{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  #   home.file.".config/monitors_source" = {
  #     source = ./monitors.xml;
  #     onChange = ''
  #       cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
  #     '';
  #   };
}
