# Shared desktop configuration for all desktop environments
# Loads DE-specific configs which handle their own display managers
{
  config,
  host,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.optional (host.gnome or false) ./gnome)
    (lib.optional (host.niri or false) ./niri)
  ];

  services = {
    # Enable user file access
    gvfs.enable = true;
    udisks2.enable = true;
    # Configure keyboard layout
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Fix for autoLogin - prevents getty from interfering
  systemd.services."getty@tty1".enable = lib.mkIf host.autoLogin false;
  systemd.services."autovt@tty1".enable = lib.mkIf host.autoLogin false;
}
