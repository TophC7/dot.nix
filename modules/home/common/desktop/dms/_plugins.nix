# DMS Plugin Definitions
# Centralized plugin configuration for DankMaterialShell
{
  lib,
  pkgs,
  ...
}:
let
  easyEffectsPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-easyeffects";
    version = "1.0.2";

    src = pkgs.fetchFromGitHub {
      owner = "jonkristian";
      repo = "dms-easyeffects";
      rev = "ac2726063d308ef28c1704956564f013951e3a0a";
      hash = "sha256-KgdACxkP4bAeg+xF1k1qspfzRwAitLMhFncydHJPfAU=";
    };

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

  dankActionsPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-dank-actions";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "AvengeMedia";
      repo = "dms-plugins";
      rev = "3bc66f186a8184cb8eca5fdfc0699cb4a828cd90";
      hash = "sha256-KtOu12NVLdyho9T4EXJaReNhFO98nAXpemkb6yeOvwE=";
    };

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

  displaySettingsPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-display-settings";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "Lucyfire";
      repo = "dms-plugins";
      rev = "b9b5b28ed868e06706d3f24c694bb79e6c8197c5";
      hash = "sha256-NY/yGH0/iSa5ym+pwxs5A9nPw/nqIMmLsiLw/+UtXLc=";
    };

    installPhase = ''
      mkdir -p $out
      cp -r displaySettings/* $out/
    '';

    meta = {
      description = "DankMaterialShell display settings plugin for screen management";
      homepage = "https://github.com/Lucyfire/dms-plugins";
      license = lib.licenses.mit;
    };
  };

  nixMonitorPlugin = pkgs.stdenv.mkDerivation {
    pname = "dms-nix-monitor";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "antonjah";
      repo = "nix-monitor";
      rev = "bd941a0e71b8f7763b45c22281a44ff554f82666";
      hash = "sha256-PotQG3LnS8LsOnsHtyS5MFBw0qbRvr3886+3nzxL6R4=";
    };

    installPhase = ''
      mkdir -p $out
      cp -r *.qml plugin.json $out/
    '';

    meta = {
      description = "DankMaterialShell Nix update monitor widget";
      homepage = "https://github.com/antonjah/nix-monitor";
      license = lib.licenses.mit;
    };
  };
in
{
  inherit
    easyEffectsPlugin
    dankActionsPlugin
    displaySettingsPlugin
    nixMonitorPlugin
    ;
}
