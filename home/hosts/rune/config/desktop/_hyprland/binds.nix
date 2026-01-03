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
  system = pkgs.stdenv.hostPlatform.system;
  zen-browser = inputs.zen-browser.packages.${system}.beta;
  hyprnavi = lib.getExe inputs.hyprnavi-psm.packages.${system}.default;
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
      "$mod, D, layoutmsg, fit visible" # fits all visible windows onto screen space
      "$mod, P, togglefloating"
      "$mod, S, togglegroup" # Column tabbed display equivalent
      "$mod SUPER, F, fullscreen"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # NAVIGATION & MOVEMENT (hyprnavi-psm)
      # ══════════════════════════════════════════════════════════════════════════
      # hyprnavi flags: -p position-based | -s swap/move | -m cross-monitor
      #
      # Focus: L/R crosses monitors at edges, U/D crosses workspace at edges
      "$mod, C, exec, ${hyprnavi} l -pm"
      "$mod, B, exec, ${hyprnavi} r -pm"
      "$mod, T, exec, ${hyprnavi} u -p"
      "$mod, V, exec, ${hyprnavi} d -p"
      # Move window: L/R crosses monitors, U/D crosses workspace at edges
      "$mod CTRL, C, exec, ${hyprnavi} l -psm"
      "$mod CTRL, B, exec, ${hyprnavi} r -psm"
      "$mod CTRL, T, exec, ${hyprnavi} u -ps"
      "$mod CTRL, V, exec, ${hyprnavi} d -ps"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # RESIZING
      # ══════════════════════════════════════════════════════════════════════════
      #
      # Column width (cycle presets)
      "$mod SUPER, C, layoutmsg, colresize -conf"
      "$mod SUPER, B, layoutmsg, colresize +conf"
      # Window height
      "$mod SUPER, T, resizeactive, 0 -50"
      "$mod SUPER, V, resizeactive, 0 50"

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
