# Niri desktop stack and Wayland needs.
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ];

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.niri-unstable;
  };

  services.displayManager.defaultSession = lib.mkDefault "niri";

  xdg.portal = {
    enable = lib.mkDefault true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.niri = {
      default = lib.mkDefault [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Screenshot" = lib.mkDefault [ "gnome" ];
      "org.freedesktop.impl.portal.Screencast" = lib.mkDefault [ "gnome" ];
    };
  };

  systemd.user.services.niri-flake-polkit.enable = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    clapper
    eloquent
    gnome-disk-utility
    kooha
    libnotify
    loupe
    pavucontrol
    playerctl
    qdirstat
    wev
    wf-recorder
    wireplumber
    wl-clipboard-rs
  ];

  programs.nm-applet = {
    enable = lib.mkDefault true;
    indicator = lib.mkDefault true;
  };

  security.polkit.enable = lib.mkDefault true;
  services.gnome.gnome-keyring.enable = lib.mkDefault true;

  services.geoclue2.enable = lib.mkDefault true;

  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkDefault "suspend";
    HandleLidSwitchExternalPower = lib.mkDefault "lock";
  };

  environment.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = lib.mkDefault "1";
    ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "wayland";
    MOZ_ENABLE_WAYLAND = lib.mkDefault "1";
    NIXOS_OZONE_WL = lib.mkDefault "1";
    QT_QPA_PLATFORM = lib.mkDefault "wayland";
    SDL_VIDEODRIVER = lib.mkDefault "wayland";
    XDG_SESSION_TYPE = lib.mkDefault "wayland";
  };

  fonts.fontconfig = {
    enable = lib.mkDefault true;
    antialias = lib.mkDefault true;
    hinting.enable = lib.mkDefault true;
    subpixel.rgba = lib.mkDefault "rgb";
  };
}
