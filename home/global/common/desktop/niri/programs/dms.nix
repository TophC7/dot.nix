{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Declaratively fetch the DankActions plugin
  dankActionsPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-dank-actions";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "AvengeMedia";
      repo = "dms-plugins";
      rev = "3bc66f186a8184cb8eca5fdfc0699cb4a828cd90";
      hash = "sha256-KtOu12NVLdyho9T4EXJaReNhFO98nAXpemkb6yeOvwE=";
    };

    # Plugin files are in DankActions subdirectory
    installPhase = ''
      mkdir -p $out
      cp -r DankActions/* $out/
    '';

    meta = {
      description = "DankMaterialShell DankActions plugin";
      homepage = "https://github.com/AvengeMedia/dms-plugins";
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
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableClipboard = false; # Clipboard history manager
    enableVPN = true; # VPN management widget
    enableBrightnessControl = true; # Backlight/brightness controls
    enableColorPicker = true; # Color picker tool
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableSystemSound = true; # System sound effects

    niri = {
      enableSpawn = true; # Auto-start DMS with niri
    };

    # Plugins
    plugins = {
      dankActions = {
        enable = true;
        src = dankActionsPlugin;
      };
    };
  };
}
