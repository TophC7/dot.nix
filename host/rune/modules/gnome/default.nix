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
    gnomeExtensions.tiling-shell
    gnomeExtensions.dash-to-panel
    gnomeExtensions.blur-my-shell
  ];

  environment.gnome.excludePackages = (
    with pkgs;
    [
      atomix # puzzle game
      epiphany # web browser
      evince # document viewer
      gedit # text editor
      gnome-help
      gnome-maps
      gnome-music
      gnome-photos
      gnome-terminal
      gnome-tour
      hitori # sudoku game
      iagno # go game
      tali # poker game
    ]
  );

}
