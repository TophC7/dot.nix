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
      input = lib.mkDefault {
        mod-key = "Super";
        mod-key-nested = "Alt";
      };
      binds =
        let
          zen-browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
        in
        lib.mkDefault {
          # Application launchers
          "Mod+T".action.spawn = lib.getExe pkgs.ghostty;
          "Mod+E".action.spawn = lib.getExe pkgs.vscode;
          "Mod+W".action.spawn = lib.getExe zen-browser;
          "Mod+F".action.spawn = lib.getExe pkgs.nautilus;

          "Mod+Space".action.spawn = [
            "vicinae"
            "toggle"
          ]; # Application launcher

          "Mod+A".action.spawn = [
            "dms"
            "ipc"
            "notifications"
            "toggle"
          ]; # Notification center

          "Mod+Comma".action.spawn = [
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

          "Mod+V".action.spawn = [
            "vicinae"
            "vicinae://extensions/vicinae/clipboard/history"
          ]; # Clipboard manager

          "Mod+Tab".action.spawn = [
            "vicinae"
            "vicinae://extensions/vicinae/wm/switch-windows"
          ]; # Window switcher

          "Mod+X".action.spawn = [
            "dms"
            "ipc"
            "powermenu"
            "toggle"
          ]; # Power menu

          "Mod+P".action.spawn = [
            "dms"
            "ipc"
            "notepad"
            "toggle"
          ]; # Notepad

          "Mod+N".action.spawn = [
            "dms"
            "ipc"
            "night"
            "toggle"
          ]; # Night mode

          # System controls
          "Ctrl+Alt+Delete".action.quit = { }; # Exit Niri
          "Ctrl+Alt+Escape".action.spawn = [
            "loginctl"
            "terminate-user"
            "$USER"
          ];

          "Mod+L".action.spawn = [
            "dms"
            "ipc"
            "lock"
          ]; # DMS lock screen (replaces swaylock)

          "Mod+Shift+A".action.toggle-overview = { };
          "Mod+F1".action.show-hotkey-overlay = { };

          # Window/Column management
          "Mod+Q".action.close-window = { };
          "Mod+C".action.center-column = { };
          "Mod+D".action.toggle-window-floating = { }; # Kept (DMS notepad moved to Mod+Shift+P)
          "Mod+S".action.toggle-column-tabbed-display = { }; # Kept (DMS settings moved to Mod+Comma)

          # Window focus (Arrow keys)
          "Mod+Left".action.focus-column-or-monitor-left = { };
          "Mod+Right".action.focus-column-or-monitor-right = { };
          "Mod+Up".action.focus-window-or-workspace-up = { };
          "Mod+Down".action.focus-window-or-workspace-down = { };

          # Window movement
          "Mod+Shift+Left".action.consume-or-expel-window-left = { };
          "Mod+Shift+Right".action.consume-or-expel-window-right = { };
          "Mod+Shift+Up".action.move-window-up = { };
          "Mod+Shift+Down".action.move-window-down = { };

          # Monitor/Workspace movement
          "Mod+Ctrl+Left".action.move-column-to-monitor-left = { };
          "Mod+Ctrl+Right".action.move-column-to-monitor-right = { };
          "Mod+Ctrl+Up".action.move-column-to-workspace-up = { };
          "Mod+Ctrl+Down".action.move-column-to-workspace-down = { };

          # Window sizing
          "Mod+Alt+Left".action.switch-preset-column-width-back = { };
          "Mod+Alt+Right".action.switch-preset-column-width = { };
          "Mod+Alt+Up".action.set-window-height = "+10%";
          "Mod+Alt+Down".action.set-window-height = "-10%";
          "Mod+Alt+F".action.fullscreen-window = { };

          # Screenshots
          "Print".action.screenshot = { };
          "Shift+Print".action.screenshot-screen = { };
          "Super+Print".action.screenshot-window = { };

          # Media controls (DMS)
          "XF86AudioRaiseVolume".action.spawn = [
            "dms"
            "ipc"
            "audio"
            "increment"
            "3"
          ];

          "XF86AudioLowerVolume".action.spawn = [
            "dms"
            "ipc"
            "audio"
            "decrement"
            "3"
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
            ""
          ];

          "XF86MonBrightnessDown".action.spawn = [
            "dms"
            "ipc"
            "brightness"
            "decrement"
            "5"
            ""
          ];
        };
    };
  };
}
