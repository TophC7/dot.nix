# Niri desktop stack and Wayland needs.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Upstream omits pycairo from nautilus-python's embedded module search path.
  nautilusMyComputer =
    inputs.nautilus-my-computer.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (oldAttrs: {
        postFixup = (oldAttrs.postFixup or "") + ''
          ln -s \
            ${pkgs.python3Packages.pycairo}/${pkgs.python3.sitePackages}/cairo \
            $out/share/nautilus-python/extensions/cairo

          mkdir -p $out/share/gsettings-schemas/$name/glib-2.0
          ln -s \
            $out/share/glib-2.0/schemas \
            $out/share/gsettings-schemas/$name/glib-2.0/schemas
        '';
      });
in
{
  imports = [
    inputs.niri.nixosModules.niri
    ../audio.nix
    ../ddcutil.nix
  ];

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
    code-nautilus
    eloquent
    file-roller
    gnome-disk-utility
    gnome-epub-thumbnailer
    kooha
    libnotify
    loupe
    nautilus
    nautilusMyComputer
    nautilus-python
    papers
    pavucontrol
    playerctl
    qdirstat
    sushi
    turtle
    wev
    wf-recorder
    wireplumber
    wl-clipboard-rs
  ];

  environment.pathsToLink = [ "/share/nautilus-python/extensions" ];

  programs.nm-applet = {
    enable = lib.mkDefault true;
    indicator = lib.mkDefault true;
  };

  security.polkit.enable = lib.mkDefault true;
  services.gnome.gnome-keyring.enable = lib.mkDefault true;

  services = {
    geoclue2.enable = lib.mkDefault true;
    gvfs.enable = lib.mkDefault true;
    udisks2.enable = lib.mkDefault true;
  };

  programs.nautilus-open-any-terminal.enable = lib.mkDefault true;

  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkDefault "suspend";
    HandleLidSwitchExternalPower = lib.mkDefault "lock";
  };

  environment.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = lib.mkDefault "1";
    ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "wayland";
    MOZ_ENABLE_WAYLAND = lib.mkDefault "1";
    NAUTILUS_4_EXTENSION_DIR = lib.mkDefault "${config.system.path}/lib/nautilus/extensions-4";
    NIXOS_OZONE_WL = lib.mkDefault "1";
    QT_QPA_PLATFORM = lib.mkDefault "wayland";
    SDL_VIDEODRIVER = lib.mkDefault "wayland";
    # Expose only package-local schemas; exposing its whole share directory
    # makes nautilus-python discover and load the extension a second time.
    XDG_DATA_DIRS = lib.mkAfter [
      "${nautilusMyComputer}/share/gsettings-schemas/${nautilusMyComputer.name}"
    ];
    XDG_SESSION_TYPE = lib.mkDefault "wayland";
  };

  fonts.fontconfig = {
    enable = lib.mkDefault true;
    antialias = lib.mkDefault true;
    hinting.enable = lib.mkDefault true;
    subpixel.rgba = lib.mkDefault "rgb";
  };
}
