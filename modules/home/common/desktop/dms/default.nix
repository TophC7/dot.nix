# DankMaterialShell - Unified configuration for niri and hyprland
# Automatically applies compositor-specific settings based on host.desktop
{
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Compositor detection helpers
  isNiri = host.desktop == "niri";
  isHyprland = host.desktop == "hyprland";

  # DMS shell package for Hyprland exec-once
  dms-shell = inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;

  # Import plugin definitions
  plugins = import ./_plugins.nix { inherit lib pkgs; };
in
{
  # Import DankMaterialShell modules - base + compositor-specific
  imports = lib.flatten [
    inputs.dankMaterialShell.homeModules.dank-material-shell
    (lib.optional isNiri inputs.dankMaterialShell.homeModules.dankMaterialShell.niri)
    (lib.fs.scanPaths ./.)
  ];

  # DankMaterialShell base configuration
  programs.dank-material-shell = {
    enable = true;
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)

    # Plugins
    plugins = {
      dankActions = {
        enable = true;
        src = plugins.dankActionsPlugin;
      };
      easyEffects = {
        enable = true;
        src = plugins.easyEffectsPlugin;
      };
      displaySettings = {
        enable = true;
        src = plugins.displaySettingsPlugin;
      };
      nixMonitor = {
        enable = true;
        src = plugins.nixMonitorPlugin;
      };
    };

  }
  // lib.optionalAttrs isNiri {
    # Niri-specific: Auto-start DMS with niri
    niri.enableSpawn = true;
  };

  # Hyprland-specific: Import environment to systemd and start graphical session
  wayland.windowManager.hyprland.settings = lib.mkIf isHyprland {
    exec-once = [
      # Import Wayland environment to systemd so user services can access it
      "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
      # Start graphical session target - this triggers DMS and other services
      "systemctl --user start graphical-session.target"
    ];
  };

  # DMS systemd user service for Hyprland
  # Starts automatically when graphical-session.target is activated
  systemd.user.services.dms = lib.mkIf isHyprland {
    Unit = {
      Description = "DankMaterialShell";
      Documentation = "https://github.com/AvengeMedia/dank-material-shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${dms-shell}/bin/dms run";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
