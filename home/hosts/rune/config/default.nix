{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  xdg.desktopEntries = {
    nixvm = {
      name = "NixOS VM";
      comment = "Testing VM";
      exec = ''fish -c "sudo virsh start nixos; remmina -c (sudo virsh -q domdisplay nixos)"'';
      icon = "nix-snowflake";
      type = "Application";
      terminal = false;
      categories = [
        "System"
        "Application"
      ];
    };

    win11 = {
      name = "Windows 11";
      comment = "Windows 11 VM";
      exec = ''fish -c "sudo virsh start win11; remmina -c (sudo virsh -q domdisplay win11)"'';
      icon = "windows95";
      type = "Application";
      terminal = false;
      categories = [
        "System"
        "Application"
      ];
    };
  };

  home.file.".config/monitors_source" = {
    source = ./monitors.xml;
    onChange = ''
      cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
    '';
  };
}
