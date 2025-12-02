# GNOME Display Manager (GDM) configuration
{
  config,
  host,
  lib,
  ...
}:
{
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
}
