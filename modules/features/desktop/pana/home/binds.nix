{ lib, pkgs, ... }:
{
  programs.niri.settings.binds = {
    "Mod+A".action.spawn = [
      "pana"
      "launcher"
    ];
    "Mod+X".action.spawn = [
      "pana"
      "launcher"
      "clipboard"
    ];
    "Mod+Period".action.spawn = [
      "pana"
      "launcher"
      "emoji"
    ];

    "Print".action.screenshot = { };
    "Shift+Print".action.screenshot-window = { };
    "Mod+Print".action.screenshot-screen = { };

    "XF86AudioMute".action.spawn = [
      (lib.getExe pkgs.pamixer)
      "-t"
    ];
    "XF86AudioMicMute".action.spawn = [
      (lib.getExe pkgs.pamixer)
      "--default-source"
      "-t"
    ];
  };
}
