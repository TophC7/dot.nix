# Shared desktop configuration for all desktop environments
# Handles GDM, auto-login, keyboard layout, and loads DE-specific configs
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

  services.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
    };

    autoLogin = lib.mkIf host.autoLogin {
      enable = true;
      user = host.user.name;
    };
  };

  # Configure keyboard layout
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Fix for autoLogin - prevents getty from interfering
  systemd.services."getty@tty1".enable = lib.mkIf host.autoLogin false;
  systemd.services."autovt@tty1".enable = lib.mkIf host.autoLogin false;
}
