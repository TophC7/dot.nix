{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Declaratively fetch the EasyEffects plugin
  easyEffectsPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-easyeffects";
    version = "1.0.2";

    src = pkgs.fetchFromGitHub {
      owner = "jonkristian";
      repo = "dms-easyeffects";
      rev = "ac2726063d308ef28c1704956564f013951e3a0a";
      hash = "sha256-KgdACxkP4bAeg+xF1k1qspfzRwAitLMhFncydHJPfAU=";
    };

    # Plugin files are at root level
    installPhase = ''
      mkdir -p $out
      cp -r *.qml plugin.json $out/
    '';

    meta = {
      description = "DankMaterialShell EasyEffects plugin for audio profile switching";
      homepage = "https://github.com/jonkristian/dms-easyeffects";
      license = lib.licenses.gpl3Only;
    };
  };

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
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)

    niri = {
      enableSpawn = true; # Auto-start DMS with niri
    };

    # Plugins
    plugins = {
      dankActions = {
        enable = true;
        src = dankActionsPlugin;
      };
      easyEffects = {
        enable = true;
        src = easyEffectsPlugin;
      };
    };
  };
}
