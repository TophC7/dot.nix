{
  config,
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  hyprlandPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
in
{
  imports = lib.fs.scanPaths ./.;

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
    package = hyprlandPackage;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Hyprland Cachix for faster builds
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  environment.systemPackages = with pkgs; [
    # Wayland utilities
    cliphist
    kooha
    libnotify
    wev # Wayland event viewer for debugging keybindings
    wf-recorder # Screen recording
    wl-clipboard

    # Utility
    gnome-disk-utility
    qdirstat

    # Media control
    playerctl
    pavucontrol
    wireplumber

    # Applications
    loupe # Image viewer
    clapper # Media player
  ];

  # NetworkManager applet for system tray
  programs.nm-applet = {
    enable = true;
    indicator = true;
  };

  # Enable pipewire for audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Enable brightness control via DDC/CI (for external monitors)
  hardware.i2c.enable = true;

  # Grant access to i2c devices for DDC control
  services.udev.extraRules = ''
    # Allow users in video group to access i2c devices
    KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"
  '';

  # Ensure user is in video group for DDC access
  users.users.${host.user.name}.extraGroups = [ "video" ];

  # Enable XDG desktop portal for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # For GTK file picker, etc.
    ];
    config = {
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
    };
  };

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Enable gnome-keyring for credential storage
  services.gnome.gnome-keyring.enable = true;

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # For Electron apps
    MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland
    QT_QPA_PLATFORM = "wayland"; # QT apps
    SDL_VIDEODRIVER = "wayland"; # SDL apps
    _JAVA_AWT_WM_NONREPARENTING = "1"; # Java apps
  };

  # Enable location services for night light
  services.geoclue2.enable = true;

  # Power management
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
