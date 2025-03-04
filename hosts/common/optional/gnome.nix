{ pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.color-picker
    gnomeExtensions.control-monitor-brightness-and-volume-with-ddcutil
    gnomeExtensions.dash-to-panel
    gnomeExtensions.tiling-shell
    gnomeExtensions.vitals
  ];

  environment.gnome.excludePackages = (
    with pkgs;
    [
      atomix # puzzle game
      # epiphany # web browser
      evince # document viewer
      gedit # text editor
      gnome-maps
      gnome-music
      gnome-photos
      gnome-tour
      gnomeExtensions.applications-menu
      gnomeExtensions.launch-new-instance
      gnomeExtensions.light-style
      gnomeExtensions.places-status-indicator
      gnomeExtensions.status-icons
      gnomeExtensions.system-monitor
      gnomeExtensions.window-list
      gnomeExtensions.windownavigator
      hitori # sudoku game
      iagno # go game
      tali # poker game
      yelp
    ]
  );
}
