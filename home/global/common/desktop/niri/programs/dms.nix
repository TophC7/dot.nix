{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Declaratively fetch the emoji launcher plugin
  emojiLauncherPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-emoji-launcher";
    version = "unstable-2025-10-27";

    src = pkgs.fetchFromGitHub {
      owner = "devnullvoid";
      repo = "dms-emoji-launcher";
      rev = "79bdec809481a2d65d18b02004a5d0195167d22c";
      hash = "sha256-Jpz/s6ol257xn0ERNsitEJB4lPhy+lJ0mf3InInP6i8=";
    };

    # Plugin files are at root, copy everything
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';

    meta = {
      description = "DankMaterialShell emoji launcher widget with 919+ emojis";
      homepage = "https://github.com/devnullvoid/dms-emoji-launcher";
      license = lib.licenses.mit;
    };
  };
in
{
  # Import DankMaterialShell modules
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  # DankMaterialShell configuration
  programs.dankMaterialShell = {
    enable = true;

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableClipboard = true; # Clipboard history manager
    enableVPN = true; # VPN management widget
    enableBrightnessControl = true; # Backlight/brightness controls
    enableColorPicker = true; # Color picker tool
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableSystemSound = true; # System sound effects

    # niri-specific integration
    niri = {
      # enableKeybinds = true; # Automatic keybinding configuration
      enableSpawn = true; # Auto-start DMS with niri
    };

    # Plugins
    plugins = {
      emojiLauncher = {
        enable = true;
        src = emojiLauncherPlugin;
      };
    };
  };
}
