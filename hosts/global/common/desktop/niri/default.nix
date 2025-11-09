# Niri Window Manager Configuration (System Level)
{
  config,
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
{
  # Import niri nixos module (includes home-manager integration) and greeter
  imports = [ inputs.niri.nixosModules.niri ] ++ (lib.custom.scanPaths ./.);

  # Add niri overlay for packages
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  # Enable niri at system level
  programs.niri = {
    enable = true;
    # Use unstable version which has latest fixes including libdisplay-info
    package = pkgs.niri-unstable;
  };

  # Set niri as default session (optional - uncomment to make it default)
  # services.displayManager.defaultSession = "niri";

  # Essential packages for niri
  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wev # Wayland event viewer for debugging keybindings
    grim # Screenshot utility
    slurp # Screen area selection tool
    wf-recorder # Screen recording
    wl-color-picker # Color picker for Wayland
    libnotify
    cliphist

    # Media control
    playerctl

    # Audio control
    pavucontrol
    wireplumber

    # Network manager
    networkmanagerapplet

    # Applications
    nautilus # File manager
    papers # Document viewer
    eloquent # Spell checker
  ];

  # Enable pipewire for audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Enable brightness control via DDC/CI (for external monitors)
  # This allows the brightness script to work
  hardware.i2c.enable = true;

  # Grant access to i2c devices for DDC control
  services.udev.extraRules = ''
    # Allow users in video group to access i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"
  '';

  # Ensure user is in video group for DDC access
  users.users.${host.user.name}.extraGroups = [ "video" ];

  # Enable XDG desktop portal for niri
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # For GTK file picker, etc.
      xdg-desktop-portal-gnome # For GNOME apps compatibility
    ];
    # Niri provides its own portal
    config = {
      niri = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
      };
    };
  };

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Polkit agent (required for system operations like reboot/shutdown)
  systemd.user.services.polkit-gnome-authentication-agent = {
    description = "polkit-gnome-authentication-agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # For Electron apps
    MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland
    QT_QPA_PLATFORM = "wayland"; # QT apps
    SDL_VIDEODRIVER = "wayland"; # SDL apps
    _JAVA_AWT_WM_NONREPARENTING = "1"; # Java apps
  };

  # Enable gnome-keyring for credential storage
  services.gnome.gnome-keyring.enable = true;

  # Enable location services for night light
  services.geoclue2.enable = true;

  # Allow Niri to manage power
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  # Font configuration for better rendering
  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting.enable = true;
    subpixel.rgba = "rgb";
  };
}
