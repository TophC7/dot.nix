{
  config,
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ] ++ (lib.fs.scanPaths ./.);
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  environment.systemPackages = with pkgs; [
    # Wayland utilities
    wl-clipboard-rs
    wev # Wayland event viewer for debugging keybindings
    wf-recorder # Screen recording
    kooha
    libnotify

    # Utility
    gnome-disk-utility
    qdirstat

    # Media control
    playerctl
    pavucontrol
    wireplumber

    # Applications
    eloquent # Spell checker
    loupe # Image viewer
    clapper # Media player
  ];

  # NetworkManager applet for system tray
  # Provides GUI control for network connections including WireGuard VPN
  programs.nm-applet = {
    enable = true;
    indicator = true; # Use AppIndicator mode (better for Wayland/niri)
  };

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
      # Fallback configuration for applications not running under niri
      common = {
        default = [
          "gnome"
          "gtk"
        ];
      };
    };
  };

  # Enable polkit for authentication
  security.polkit.enable = true;
  # DMS Handles the polkit agent, @home/global/common/desktop/niri/programs/dms.nix no config necessary
  # Disables the niri polkit agent to avoid conflicts
  systemd.user.services.niri-flake-polkit.enable = false;
  # Enable gnome-keyring for credential storage
  services.gnome.gnome-keyring.enable = true;

  # Environment variables for Wayland
  environment.sessionVariables = {
    # NIXOS_OZONE_WL = "1"; # For Electron apps
    MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland
    QT_QPA_PLATFORM = "wayland"; # QT apps
    SDL_VIDEODRIVER = "wayland"; # SDL apps
    _JAVA_AWT_WM_NONREPARENTING = "1"; # Java apps
  };

  # Enable location services for night light
  services.geoclue2.enable = true;

  # Allow Niri to manage power
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  # Font configuration for better rendering
  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting.enable = true;
    subpixel.rgba = "rgb";
  };
}
