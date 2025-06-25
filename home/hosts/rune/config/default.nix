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

  monitors = [
    {
      name = "DP-2";
      primary = true;
      width = 3840;
      height = 2160;
      refreshRate = 120;
      x = 0;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
      hdr = true;
      vrr = true;
    }
    {
      name = "HDMI-1";
      primary = false;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      x = 1920; # Positioned to the right of DP-1
      y = 0;
      scale = 1.0;
      transform = 1;
      enabled = true;
    }
  ];

  ## TODO:
  ## I want to automate this monitors.xml
  ## But dk how to do it properly yet.
  ## So for now ill still use this for the gnome config

  home.file.".config/monitors_source" = {
    source = ./monitors.xml;
    onChange = ''
      cp $HOME/.config/monitors_source $HOME/.config/monitors.xml
      chmod 755 $HOME/.config/monitors.xml
    '';
  };
}
