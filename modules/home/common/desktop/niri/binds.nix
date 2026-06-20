{
  inputs,
  lib,
  pkgs,

  ...
}:
{
  # Niri keybindings
  programs.niri = {
    settings = {
      input = {
        mod-key = "Super";
        mod-key-nested = "Alt";
      };
      binds =

        let
          zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
        in
        {
          #
          # ══════════════════════════════════════════════════════════════════════════
          # APPLICATION LAUNCHERS
          # ══════════════════════════════════════════════════════════════════════════
          #
          "Mod+G".action.spawn = lib.getExe pkgs.ghostty;
          "Mod+E".action.spawn = lib.getExe pkgs.vscode;
          "Mod+W".action.spawn = lib.getExe zen-browser;
          "Mod+F".action.spawn = lib.getExe pkgs.nautilus;

          "Mod+A".action.spawn = [
            "vicinae"
            "toggle"
          ]; # Application launcher

          "Mod+N".action.spawn = [
            "dms"
            "ipc"
            "notifications"
            "toggle"
          ]; # Notification center

          "Mod+Semicolon".action.spawn = [
            "dms"
            "ipc"
            "settings"
            "toggle"
          ]; # Settings

          "Mod+M".action.spawn = [
            "dms"
            "ipc"
            "processlist"
            "toggle"
          ]; # Process list (system monitor)

          "Mod+X".action.spawn = [
            "vicinae"
            "vicinae://launch/clipboard/history"
          ]; # Clipboard manager

          "Mod+Period".action.spawn = [
            "vicinae"
            "vicinae://launch/core/search-emojis"
          ]; # Emoji picker

          "Mod+Shift+X".action.spawn = [
            "dms"
            "ipc"
            "powermenu"
            "toggle"
          ]; # Power menu

          "Mod+Shift+N".action.spawn = [
            "dms"
            "ipc"
            "notepad"
            "toggle"
          ]; # Notepad

          #
          # ══════════════════════════════════════════════════════════════════════════
          # SYSTEM CONTROLS
          # ══════════════════════════════════════════════════════════════════════════
          #
          "Ctrl+Alt+Delete".action.quit = { }; # Exit Niri
          "Ctrl+Super+Delete".action.spawn = [
            "loginctl"
            "terminate-user"
            "$USER"
          ];

          "Mod+Shift+L".action.spawn = [
            "dms"
            "ipc"
            "lock"
          ]; # DMS lock screen (replaces swaylock)

          "Mod+Space".action.toggle-overview = { };
          "Mod+F1".action.show-hotkey-overlay = { };

          #
          # ══════════════════════════════════════════════════════════════════════════
          # WINDOW/COLUMN MANAGEMENT
          # ══════════════════════════════════════════════════════════════════════════
          #
          "Mod+Q".action.close-window = { };
          "Mod+D".action.center-column = { };
          "Mod+P".action.toggle-window-floating = { }; # Kept (DMS notepad moved to Mod+Shift+P)
          "Mod+S".action.toggle-column-tabbed-display = { }; # Toggle tabbed column display

          #
          # ══════════════════════════════════════════════════════════════════════════
          # NAVIGATION & MOVEMENT
          # ══════════════════════════════════════════════════════════════════════════
          #
          # Focus: L/R crosses monitors at edges, U/D crosses workspaces at edges
          "Mod+C".action.focus-column-or-monitor-left = { };
          "Mod+B".action.focus-column-or-monitor-right = { };
          "Mod+T".action.focus-window-or-workspace-up = { };
          "Mod+V".action.focus-window-or-workspace-down = { };

          # Move window: L/R crosses monitors at edge, U/D crosses workspaces at edge
          "Mod+Ctrl+C".action.consume-or-expel-window-left-or-monitor-left = [ ];
          "Mod+Ctrl+B".action.consume-or-expel-window-right-or-monitor-right = [ ];
          "Mod+Ctrl+T".action.move-window-up-or-to-workspace-up = { };
          "Mod+Ctrl+V".action.move-window-down-or-to-workspace-down = { };

          #
          # ══════════════════════════════════════════════════════════════════════════
          # RESIZING
          # ══════════════════════════════════════════════════════════════════════════
          #
          # Column width (cycle presets)
          "Mod+Alt+C".action.switch-preset-column-width-back = { };
          "Mod+Alt+B".action.switch-preset-column-width = { };
          # Window height
          "Mod+Alt+T".action.set-window-height = "+10%";
          "Mod+Alt+V".action.set-window-height = "-10%";
          "Mod+Shift+F".action.fullscreen-window = { };
          "Mod+Shift+F".allow-inhibiting = false;

          #
          # ══════════════════════════════════════════════════════════════════════════
          # SCREENSHOTS
          # ══════════════════════════════════════════════════════════════════════════
          #
          "Print".action.spawn = [
            "dms"
            "screenshot"
          ];

          "Shift+Print".action.spawn = [
            "dms"
            "screenshot"
            "window"
          ];

          "Mod+Print".action.spawn = [
            "dms"
            "screenshot"
            "full"
          ];

          #
          # ══════════════════════════════════════════════════════════════════════════
          # MEDIA CONTROLS
          # ══════════════════════════════════════════════════════════════════════════
          #
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

          "XF86AudioMute".action.spawn = [
            "dms"
            "ipc"
            "audio"
            "mute"
          ];

          "XF86AudioMicMute".action.spawn = [
            "dms"
            "ipc"
            "audio"
            "micmute"
          ];

          # Media player controls
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

          # Brightness controls (DMS)
          "XF86MonBrightnessUp".action.spawn = [
            "dms"
            "ipc"
            "brightness"
            "increment"
            "5"
          ];

          "XF86MonBrightnessDown".action.spawn = [
            "dms"
            "ipc"
            "brightness"
            "decrement"
            "5"
          ];
        };
    };
  };
}
