# Shared Niri keybindings.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
in
{
  programs.niri.settings = {
    input = {
      mod-key = "Super";
      mod-key-nested = "Alt";
    };

    binds = {
      # Applications
      "Mod+G".action.spawn = lib.getExe pkgs.ghostty;
      "Mod+E".action.spawn = lib.getExe pkgs.vscode;
      "Mod+W".action.spawn = lib.getExe zen-browser;
      "Mod+F".action.spawn = lib.getExe pkgs.nautilus;

      # Session
      "Ctrl+Alt+Delete".action.quit = { };
      "Ctrl+Super+Delete".action.spawn = [
        "loginctl"
        "terminate-user"
        "$USER"
      ];
      # This keyboard sends grave for its Escape key while a modifier is held.
      # Niri clamps workspace index 255 to its final, always-empty workspace.
      "Alt+Escape" = {
        action.focus-workspace = 255;
        allow-inhibiting = false;
        hotkey-overlay.title = "Escape Pointer Capture";
        repeat = false;
      };
      "Mod+Space".action.toggle-overview = { };
      "Mod+F1".action.show-hotkey-overlay = { };

      # Window and column management
      "Mod+Q".action.close-window = { };
      "Mod+D".action.center-column = { };
      "Mod+P".action.toggle-window-floating = { };
      "Mod+S".action.toggle-column-tabbed-display = { };

      # Focus: left/right crosses monitors; up/down crosses workspaces.
      "Mod+C".action.focus-column-or-monitor-left = { };
      "Mod+B".action.focus-column-or-monitor-right = { };
      "Mod+T".action.focus-window-or-workspace-up = { };
      "Mod+V".action.focus-window-or-workspace-down = { };

      # Move windows across columns, monitors, and workspaces.
      "Mod+Ctrl+C".action.consume-or-expel-window-left-or-monitor-left = [ ];
      "Mod+Ctrl+B".action.consume-or-expel-window-right-or-monitor-right = [ ];
      "Mod+Ctrl+T".action.move-window-up-or-to-workspace-up = { };
      "Mod+Ctrl+V".action.move-window-down-or-to-workspace-down = { };

      # Resize
      "Mod+Alt+C".action.switch-preset-column-width-back = { };
      "Mod+Alt+B".action.switch-preset-column-width = { };
      "Mod+Alt+T".action.set-window-height = "+10%";
      "Mod+Alt+V".action.set-window-height = "-10%";
      "Mod+Shift+F" = {
        action.fullscreen-window = { };
        allow-inhibiting = false;
      };

      # Media
      "XF86AudioRaiseVolume".action.spawn = [
        "${pkgs.pamixer}/bin/pamixer"
        "-i"
        "5"
      ];
      "XF86AudioLowerVolume".action.spawn = [
        "${pkgs.pamixer}/bin/pamixer"
        "-d"
        "5"
      ];
      "XF86AudioPlay".action.spawn = [
        "${pkgs.playerctl}/bin/playerctl"
        "play-pause"
      ];
      "XF86AudioNext".action.spawn = [
        "${pkgs.playerctl}/bin/playerctl"
        "next"
      ];
      "XF86AudioPrev".action.spawn = [
        "${pkgs.playerctl}/bin/playerctl"
        "previous"
      ];
    };
  };
}
