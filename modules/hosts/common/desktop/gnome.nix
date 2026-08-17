# Stock GNOME session. GNOME settings remain user-owned through its GUI.
{
  host,
  lib,
  pkgs,
  ...
}:
{
  services = {
    desktopManager.gnome.enable = lib.mkDefault true;
    gnome.gnome-remote-desktop.enable = true;

    displayManager = {
      defaultSession = lib.mkDefault "gnome";
      gdm.enable = lib.mkDefault true;
      autoLogin = {
        enable = lib.mkDefault true;
        user = lib.mkDefault host.user.name;
      };
    };
  };

  # GNOME Settings hides Remote Desktop unless the system unit is enabled or disabled.
  # NixOS links package units without honoring their upstream install target.
  systemd.services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];

  networking.firewall.allowedTCPPorts = [ 3389 ];

  environment = {
    systemPackages = with pkgs; [
      gnome-tweaks
      resources
      gnomeExtensions.copyous
    ];

    gnome.excludePackages = with pkgs; [
      atomix
      baobab
      evince
      geary
      gedit
      gnome-console
      gnome-contacts
      gnome-maps
      gnome-music
      gnome-photos
      gnome-terminal
      gnome-tour
      gnome-user-docs
      gnomeExtensions.applications-menu
      gnomeExtensions.launch-new-instance
      gnomeExtensions.light-style
      gnomeExtensions.places-status-indicator
      gnomeExtensions.status-icons
      gnomeExtensions.system-monitor
      gnomeExtensions.window-list
      gnomeExtensions.windownavigator
      hitori
      iagno
      monitor
      simple-scan
      tali
      yelp
    ];
  };
}
