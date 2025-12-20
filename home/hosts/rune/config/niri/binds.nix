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
        mod-key = "Alt";
        mod-key-nested = "Super";
      };
      binds =

        let
          zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
        in
        {
          # Application launchers
          "Mod+G".action.spawn = lib.getExe pkgs.ghostty;
          "Mod+E".action.spawn = [
            (lib.getExe pkgs.vscode)
            "--ozone-platform=x11"
          ];
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
            "vicinae://extensions/vicinae/clipboard/history"
          ]; # Clipboard manager

          "Mod+Period".action.spawn = [
            "vicinae"
            "vicinae://extensions/vicinae/vicinae/search-emojis"
          ]; # Clipboard manager

          # "Mod+Tab".action.spawn = [
          #   "vicinae"
          #   "vicinae://extensions/vicinae/wm/switch-windows"
          # ]; # Window switcher

          "Mod+Shift+X".action.spawn = [
            "dms"
            "ipc"
            "powermenu"
            "toggle"
          ]; # Power menu

          "Mod+Super+N".action.spawn = [
            "dms"
            "ipc"
            "notepad"
            "toggle"
          ]; # Notepad

          # System controls
          "Ctrl+Alt+Delete".action.quit = { }; # Exit Niri
          "Ctrl+Super+Delete".action.spawn = [
            "loginctl"
            "terminate-user"
            "$USER"
          ];

          "Mod+Super+L".action.spawn = [
            "dms"
            "ipc"
            "lock"
          ]; # DMS lock screen (replaces swaylock)

          "Mod+Super+A".action.toggle-overview = { };
          "Mod+F1".action.show-hotkey-overlay = { };

          # Window/Column management
          "Mod+Q".action.close-window = { };
          "Mod+D".action.center-column = { };
          "Mod+P".action.toggle-window-floating = { }; # Kept (DMS notepad moved to Mod+Shift+P)
          "Mod+S".action.toggle-column-tabbed-display = { }; # Kept (DMS settings moved to Mod+Comma)

          # Window focus
          "Mod+C".action.focus-column-or-monitor-left = { };
          "Mod+B".action.focus-column-or-monitor-right = { };
          "Mod+T".action.focus-window-or-workspace-up = { };
          "Mod+V".action.focus-window-or-workspace-down = { };

          # Window movement
          "Mod+Shift+C".action.consume-or-expel-window-left = { };
          "Mod+Shift+B".action.consume-or-expel-window-right = { };
          "Mod+Shift+T".action.move-window-up = { };
          "Mod+Shift+V".action.move-window-down = { };

          # Monitor/Workspace movement
          "Mod+Ctrl+C".action.move-column-to-monitor-left = { };
          "Mod+Ctrl+B".action.move-column-to-monitor-right = { };
          "Mod+Ctrl+T".action.move-column-to-workspace-up = { };
          "Mod+Ctrl+V".action.move-column-to-workspace-down = { };

          # Window sizing
          "Mod+Super+C".action.switch-preset-column-width-back = { };
          "Mod+Super+B".action.switch-preset-column-width = { };
          "Mod+Super+T".action.set-window-height = "+10%";
          "Mod+Super+V".action.set-window-height = "-10%";
          "Mod+Super+F".action.fullscreen-window = { };

          # Screenshots
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

          # Media controls (DMS)
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

          # Media player controlss
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
