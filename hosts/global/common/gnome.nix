{ pkgs, config, ... }:
{
  ## DE ##

  services.xserver = {
    enable = true;

    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.mutter ];
      extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['scale-monitor-framebuffer']
      '';
    };
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      autoLogin = {
        enable = true;
        user = config.hostSpec.username;
      };
    };

    xkb = {
      layout = "us";
      variant = "";
    };
  };

  #INFO: Fix for autoLogin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.color-picker
    gnomeExtensions.control-monitor-brightness-and-volume-with-ddcutil
    gnomeExtensions.dash-in-panel
    gnomeExtensions.just-perfection
    gnomeExtensions.pano
    gnomeExtensions.paperwm
    gnomeExtensions.quick-settings-audio-devices-hider
    gnomeExtensions.quick-settings-audio-devices-renamer
    gnomeExtensions.undecorate
    gnomeExtensions.vitals
  ];

  ## Exclusions ##
  services.xserver.excludePackages = [ pkgs.xterm ];
  environment.gnome.excludePackages = (
    with pkgs;
    [
      atomix
      baobab
      # epiphany
      # evince
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
      simple-scan
      tali
      yelp
    ]
  );
}
