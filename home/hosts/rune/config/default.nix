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
      name = "DP-5"; # Dell U2417H - 1080p Monitor (LEFT side, portrait)
      primary = false;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      x = 0; # Left-most monitor
      y = 0;
      scale = 1.0;
      transform = 3; # 270° rotation for portrait mode
      enabled = true;
    }
    {
      name = "DP-3"; # ASUSTek PG42UQ - 4K Gaming Monitor (RIGHT side, primary)
      primary = true;
      width = 3840;
      height = 2160;
      refreshRate = 120;
      x = 1080; # Positioned to the right of DP-5 (1920x1080 rotated = 1080 wide)
      y = 0;
      scale = 1.0;
      transform = 0;
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
