# GNOME Desktop Environment Configuration
{
  config,
  host,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.fs.scanPaths ./.;

  # Portal configuration for GNOME
  # Prevents warning about xdg-desktop-portal 1.17+ requiring explicit config
  xdg.portal.config.common.default = "*";

  ## GNOME Desktop Environment ##
  services = {
    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.mutter ];
      extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['scale-monitor-framebuffer']
      '';
    };

    gnome.core-apps.enable = true;

    # Set GNOME as default session
    # displayManager.defaultSession = lib.mkForce "gnome";

    # Disable xserver (pure Wayland)
    xserver.enable = false;

    udev.packages = with pkgs; [ gnome-settings-daemon ];
  };

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    papers # evince replacement
    eloquent # Spell checker
    resources
    cartridges
    nautilus-python
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.appindicator
    gnomeExtensions.auto-accent-colour
    gnomeExtensions.blur-my-shell
    gnomeExtensions.color-picker
    gnomeExtensions.control-monitor-brightness-and-volume-with-ddcutil
    gnomeExtensions.dash-in-panel
    gnomeExtensions.flickernaut
    gnomeExtensions.just-perfection
    gnomeExtensions.pano
    gnomeExtensions.paperwm
    gnomeExtensions.quick-settings-audio-devices-hider
    gnomeExtensions.quick-settings-audio-devices-renamer
    gnomeExtensions.undecorate
    gnomeExtensions.vitals
  ];

  ## Exclusions ##
  environment.gnome.excludePackages = (
    with pkgs;
    [
      atomix
      baobab
      # epiphany
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
    ]
  );
}
