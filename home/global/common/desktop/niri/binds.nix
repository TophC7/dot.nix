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

      # Keybindings
      binds = {
        # Application launchers
        "Mod+G".action.spawn = lib.getExe pkgs.ghostty;
        "Mod+E".action.spawn = lib.getExe pkgs.vscode;
        "Mod+W".action.spawn = lib.getExe inputs.zen-browser.packages.${pkgs.system}.default;
        "Mod+F".action.spawn = lib.getExe pkgs.nautilus;

        # DankMaterialShell keybinds
        "Mod+A".action.spawn = [
          "dms"
          "ipc"
          "spotlight"
          "toggle"
        ]; # Application launcher

        "Mod+N".action.spawn = [
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

        "Mod+X".action.spawn = [
          "dms"
          "ipc"
          "clipboard"
          "toggle"
        ]; # Clipboard manager (your custom keybind!)

        "Mod+Shift+X".action.spawn = [
          "dms"
          "ipc"
          "powermenu"
          "toggle"
        ]; # Power menu

        "Mod+Shift+P".action.spawn = [
          "dms"
          "ipc"
          "notepad"
          "toggle"
        ]; # Notepad

        "Mod+Alt+N".action.spawn = [
          "dms"
          "ipc"
          "night"
          "toggle"
        ]; # Night mode

        # System controls
        "Mod+Alt+Escape".action.quit = { }; # Exit Niri
        "Ctrl+Alt+Delete".action.spawn = [
          "loginctl"
          "terminate-user"
          "$USER"
        ];

        "Super+Alt+L".action.spawn = [
          "dms"
          "ipc"
          "lock"
          "lock"
        ]; # DMS lock screen (replaces swaylock)

        "Mod+Alt+A".action.toggle-overview = { };
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
        "Mod+Alt+C".action.switch-preset-column-width-back = { };
        "Mod+Alt+B".action.switch-preset-column-width = { };
        "Mod+Alt+T".action.set-window-height = "+10%";
        "Mod+Alt+V".action.set-window-height = "-10%";
        "Mod+Alt+F".action.fullscreen-window = { };

        # Screenshots
        "Print".action.screenshot = { };
        "Shift+Print".action.screenshot-screen = { };
        "Alt+Print".action.screenshot-window = { };

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
