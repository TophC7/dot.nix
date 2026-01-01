# Window rules using Hyprland 0.53+ syntax
# Format: windowrule = EFFECT VALUE, match:PROPERTY REGEX
# Reference: https://wiki.hypr.land/Configuring/Window-Rules/
# Matches niri window.nix configuration
{
  lib,
  ...
}:
{
  wayland.windowManager.hyprland.settings = {
    # Window rules (0.53+ syntax with match: prefix)
    windowrule = lib.mkDefault [
      #
      # ══════════════════════════════════════════════════════════════════════════
      # QUICKSHELL / DMS PANELS (Settings, System Monitor, Add Widget)
      # ══════════════════════════════════════════════════════════════════════════
      #
      "float on, match:class ^(org\\.quickshell)$"
      "size 40% 60%, match:class ^(org\\.quickshell)$, match:title ^(Settings|System Monitor|Add Widget)$"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # CODE EDITORS
      # ══════════════════════════════════════════════════════════════════════════
      #
      "size 65% 100%, match:class ^(code-url-handler|code|Code)$"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # BROWSERS
      # ══════════════════════════════════════════════════════════════════════════
      #
      "size 65% 100%, match:class ^(firefox|zen-alpha|zen-beta|zen)$"

      # Browser extensions - floating popup style
      "float on, match:title ^(Extension:.*)$"
      "size 20% 40%, match:title ^(Extension:.*)$"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # COMMUNICATION APPS (Discord, Vesktop, Telegram)
      # ══════════════════════════════════════════════════════════════════════════
      #
      "size 100% 100%, match:class ^(discord|vesktop)$"
      "size 100% 100%, match:class ^(org\\.telegram\\.desktop|TelegramDesktop)$"
      "monitor DP-5, match:class ^(discord|vesktop)$"
      "monitor DP-5, match:class ^(org\\.telegram\\.desktop|TelegramDesktop)$"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # FILE MANAGER & TERMINAL
      # ══════════════════════════════════════════════════════════════════════════
      #
      "float on, match:class ^(org\\.gnome\\.Nautilus)$"
      "size 40% 40%, match:class ^(org\\.gnome\\.Nautilus)$"
      "float on, match:class ^(com\\.mitchellh\\.ghostty)$"
      "size 40% 40%, match:class ^(com\\.mitchellh\\.ghostty)$"
      "float on, match:title ^(ghostty)$"
      "size 40% 40%, match:title ^(ghostty)$"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # GAMING
      # ══════════════════════════════════════════════════════════════════════════
      #
      "fullscreen on, match:class ^(\\.gamescope-wrapped|steam_app_.*)$"
      "immediate on, match:class ^(\\.gamescope-wrapped|steam_app_.*)$"

      #
      # ══════════════════════════════════════════════════════════════════════════
      # COMMON DIALOGS
      # ══════════════════════════════════════════════════════════════════════════
      #
      "float on, match:title ^(Open|Save|File|Folder).*$"
      "float on, match:title ^(Open File|Save File|Save As).*$"
      "float on, match:class ^(org\\.gnome\\.Calculator)$"
      "float on, match:class ^(pavucontrol)$"
      "float on, match:class ^(nm-connection-editor)$"
      "float on, match:class ^(blueman-manager)$"

      # Picture-in-picture
      "float on, match:title ^(Picture.in.Picture|Picture in Picture)$"
      "pin on, match:title ^(Picture.in.Picture|Picture in Picture)$"
      "size 640 360, match:title ^(Picture.in.Picture|Picture in Picture)$"

      # File picker dialogs
      "float on, match:class ^(xdg-desktop-portal.*)$"

      # XWayland windows - distinct border color #581C1C
      "border_color rgb(581C1C), match:xwayland 1"
    ];

    # Layer rules (for bars, notifications, overlays)
    layerrule = lib.mkDefault [
      "no_anim on, match:namespace ^(dms)$"
    ];
  };
}
