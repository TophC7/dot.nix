# Shared desktop configuration for all desktop environments
# Loads DE-specific configs which handle their own display managers
#
{
  config,
  host,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.optional (host.desktop == "gnome") ./gnome)
    (lib.optional (host.desktop == "niri") ./niri)
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
  systemd.services."getty@tty1".enable = lib.mkIf (host.autoLogin or false) false;
  systemd.services."autovt@tty1".enable = lib.mkIf (host.autoLogin or false) false;
}
