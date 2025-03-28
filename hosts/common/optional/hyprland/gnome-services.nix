{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    file-roller
    nautilus
  ];

  services = {
    # needed for GNOME services outside of GNOME Desktop
    dbus.packages = with pkgs; [
      gcr
      gnome-keyring
      gnome-settings-daemon
      gvfs
    ];

    gnome.gnome-keyring.enable = true;

    gvfs.enable = true;
  };
}
