# DMS Plugin Definitions
# NOTE: This file is prefixed with _ to exclude from auto-discovery
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  mkPlugin =
    {
      pname,
      src,
      subdir ? null,
      description,
      homepage,
      license,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname src;
      version = src.shortRev or src.lastModifiedDate or "unstable";

      installPhase =
        let
          srcPath = if subdir != null then "${src}/${subdir}" else src;
        in
        ''
          mkdir -p $out
          cp -r ${srcPath}/* $out/
        '';

      meta = { inherit description homepage license; };
    };
in
{
  dankActionsPlugin = mkPlugin {
    pname = "dms-dank-actions";
    src = inputs.dms-actions;
    subdir = "DankActions";
    description = "DankMaterialShell DankActions plugin";
    homepage = "https://github.com/AvengeMedia/dms-plugins";
    license = lib.licenses.mit;
  };

  easyEffectsPlugin = mkPlugin {
    pname = "dms-easyeffects";
    src = inputs.dms-easyeffects;
    description = "DankMaterialShell EasyEffects plugin for audio profile switching";
    homepage = "https://github.com/jonkristian/dms-easyeffects";
    license = lib.licenses.gpl3Only;
  };

  quickTotePlugin = mkPlugin {
    pname = "dms-quick-tote";
    src = inputs.dms-quick-tote;
    description = "DankMaterialShell Quick Tote plugin for pinned files, downloads, and screenshots";
    homepage = "https://github.com/JDKamalakar/DMS-Quick_Tote";
    license = lib.licenses.mit;
  };

  clipboardPlusPlugin = mkPlugin {
    pname = "dms-clipboard-plus";
    src = inputs.dms-clipboard-plus;
    subdir = "ClipboardPlus";
    description = "DankMaterialShell advanced clipboard manager plugin";
    homepage = "https://github.com/Dadangdut33/dms-plugins/tree/master/ClipboardPlus";
    license = lib.licenses.mit;
  };

  githubHeatmapPlugin = mkPlugin {
    pname = "dms-github-heatmap";
    src = inputs.dms-github-heatmap;
    description = "DankMaterialShell GitHub contribution heatmap plugin";
    homepage = "https://github.com/JDKamalakar/DMS-GitHub_HeatMap";
    license = lib.licenses.mit;
  };

  amdGpuMonitorPlugin = mkPlugin {
    pname = "dms-amd-gpu-monitor";
    src = inputs.dms-amd-gpu-monitor;
    description = "DankMaterialShell AMD GPU monitor plugin";
    homepage = "https://github.com/JDKamalakar/DMS-AMD_GPU_Monitor_Revive";
    license = lib.licenses.mit;
  };

  catWidgetPlugin = mkPlugin {
    pname = "dms-cat-widget";
    src = inputs.dms-cat-widget;
    description = "DankMaterialShell animated CPU cat widget plugin";
    homepage = "https://github.com/xi-ve/cat-dms";
    license = lib.licenses.mit;
  };

  aiUsagePlugin = inputs.dms-plugins.packages.${system}.aiUsage;

  ankerC200Plugin = inputs.anker-c200.packages.${system}.ankerC200;
}
