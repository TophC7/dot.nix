# Rune-specific Hyprland keybindings
# Matches the niri keybind layout with Alt as mod key
# Uses hyprscrolling plugin for niri-like column management
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
  wayland.windowManager.hyprland.settings = {
    # Use Alt as primary mod (like niri config)
    "$mod" = "ALT";

    bind = [
      #
      # ══════════════════════════════════════════════════════════════════════════
      # APPLICATION LAUNCHERS
      # ══════════════════════════════════════════════════════════════════════════
      #
      "$mod, G, exec, ${lib.getExe pkgs.ghostty}"
      "$mod, E, exec, ${lib.getExe pkgs.vscode}"
      "$mod, W, exec, ${lib.getExe zen-browser}"
      "$mod, F, exec, ${lib.getExe pkgs.nautilus}"

      # Vicinae launchers (application launcher, clipboard, emoji)
      "$mod, A, exec, vicinae toggle"
      "$mod, X, exec, vicinae vicinae://extensions/vicinae/clipboard/history"
      "$mod, Period, exec, vicinae vicinae://extensions/vicinae/vicinae/search-emojis"

      # DMS panels
      "$mod, N, exec, dms ipc notifications toggle"
      "$mod, Semicolon, exec, dms ipc settings toggle"
      "$mod, M, exec, dms ipc processlist toggle"
      "$mod SHIFT, X, exec, dms ipc powermenu toggle"
      "$mod SUPER, N, exec, dms ipc notepad toggle"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # SYSTEM CONTROLS
      # ══════════════════════════════════════════════════════════════════════════
      #
      "CTRL ALT, Delete, exit" # Exit Hyprland
      "CTRL SUPER, Delete, exec, loginctl terminate-user $USER"
      "$mod SUPER, L, exec, dms ipc lock" # DMS lock screen

      # Hyprspace overview (like niri's toggle-overview)
      # "$mod SUPER, A, overview:toggle"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # WINDOW/COLUMN MANAGEMENT
      # ══════════════════════════════════════════════════════════════════════════
      #
      "$mod, Q, killactive"
      "$mod, D, centerwindow"
      "$mod, P, togglefloating"
      "$mod, S, togglegroup" # Column tabbed display equivalent
      "$mod SUPER, F, fullscreen"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # FOCUS NAVIGATION (hyprscrolling)
      # ══════════════════════════════════════════════════════════════════════════
      #
      # Column focus (left/right) - uses hyprscrolling's focus with wrapping
      "$mod, C, layoutmsg, focus l"
      "$mod, B, layoutmsg, focus r"
      # Window focus within column (up/down)
      "$mod, T, movefocus, u"
      "$mod, V, movefocus, d"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # WINDOW MOVEMENT (hyprscrolling)
      # ══════════════════════════════════════════════════════════════════════════
      #
      # Move window between columns (consume/expel like niri)
      "$mod SHIFT, C, layoutmsg, movewindowto l"
      "$mod SHIFT, B, layoutmsg, movewindowto r"
      # Move window within column
      "$mod SHIFT, T, movewindow, u"
      "$mod SHIFT, V, movewindow, d"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # COLUMN/MONITOR MOVEMENT
      # ══════════════════════════════════════════════════════════════════════════
      #
      # Move entire column to monitor
      "$mod CTRL, C, movewindow, mon:l"
      "$mod CTRL, B, movewindow, mon:r"
      # Move column to workspace (up/down)
      "$mod CTRL, T, movetoworkspace, e-1"
      "$mod CTRL, V, movetoworkspace, e+1"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # COLUMN SIZING (hyprscrolling)
      # ══════════════════════════════════════════════════════════════════════════
      #
      # Cycle through preset column widths (like niri's switch-preset-column-width)
      "$mod SUPER, C, layoutmsg, colresize -conf"
      "$mod SUPER, B, layoutmsg, colresize +conf"
      # Adjust window height
      "$mod SUPER, T, resizeactive, 0 -50"
      "$mod SUPER, V, resizeactive, 0 50"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # WORKSPACE SWITCHING
      # ══════════════════════════════════════════════════════════════════════════
      #
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"
      "$mod, 0, workspace, 10"

      # Move window to workspace
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"

      # Workspace scroll
      "$mod, mouse_down, workspace, e+1"
      "$mod, mouse_up, workspace, e-1"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # SCREENSHOTS (DMS)
      # ══════════════════════════════════════════════════════════════════════════
      #
      ", Print, exec, dms screenshot"
      "SHIFT, Print, exec, dms screenshot window"
      "$mod, Print, exec, dms screenshot full"
    ];

    # Mouse bindings
    bindm = [
      ", mouse:275, movewindow"
      ", mouse:276, resizewindow"
    ];

    # Media keys (repeatable) - volume uses pamixer directly
    bindel = [
      ", XF86AudioRaiseVolume, exec, ${pkgs.pamixer}/bin/pamixer -i 5"
      ", XF86AudioLowerVolume, exec, ${pkgs.pamixer}/bin/pamixer -d 5"
    ];

    # Media/brightness keys (non-repeatable) - uses DMS for OSD integration
    bindl = [
      ", XF86AudioMute, exec, dms ipc audio mute"
      ", XF86AudioMicMute, exec, dms ipc audio micmute"
      ", XF86AudioPlay, exec, ${lib.getExe pkgs.playerctl} play-pause"
      ", XF86AudioNext, exec, ${lib.getExe pkgs.playerctl} next"
      ", XF86AudioPrev, exec, ${lib.getExe pkgs.playerctl} previous"
      ", XF86MonBrightnessUp, exec, dms ipc brightness increment 5"
      ", XF86MonBrightnessDown, exec, dms ipc brightness decrement 5"
    ];
  };
}
