{
  config,
  host,
  lib,
  pkgs,
  ...
}:
{
  ## DE ##
  services = {
    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.mutter ];
      extraGSettingsOverrides = ''
        [org.gnome.mutter]
        experimental-features=['scale-monitor-framebuffer']
      '';
    };

    # hosts/global/core/ssh.nix handles this
    gnome.gcr-ssh-agent.enable = false;
    gnome.core-apps.enable = true;

    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };

      # Set the custom session as default
      defaultSession = lib.mkForce "gnome";

      autoLogin = {
        enable = true;
        user = host.user.name;
      };
    };

    # Configure keyboard layout for Wayland
    xserver = {
      enable = false;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    udev.packages = with pkgs; [ gnome-settings-daemon ];
  };

  #INFO: Fix for autoLogin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

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
