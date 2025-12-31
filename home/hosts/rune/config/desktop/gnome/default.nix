{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  home.file.".config/monitors_source" = {
    source = ./monitors.xml;
    onChange = ''
      cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
      chmod 755 $HOME/.config/monitors.xml
    '';
  };
}
