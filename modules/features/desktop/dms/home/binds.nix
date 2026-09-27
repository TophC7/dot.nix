_: {
  programs.niri.settings.binds = {
    "Mod+A".action.spawn = [
      "vicinae"
      "toggle"
    ];
    "Mod+N".action.spawn = [
      "dms"
      "ipc"
      "notifications"
      "toggle"
    ];
    "Mod+Semicolon".action.spawn = [
      "dms"
      "ipc"
      "settings"
      "toggle"
    ];
    "Mod+M".action.spawn = [
      "dms"
      "ipc"
      "processlist"
      "toggle"
    ];
    "Mod+X".action.spawn = [
      "vicinae"
      "vicinae://launch/clipboard/history"
    ];
    "Mod+Period".action.spawn = [
      "vicinae"
      "vicinae://launch/core/search-emojis"
    ];
    "Mod+Shift+X".action.spawn = [
      "dms"
      "ipc"
      "powermenu"
      "toggle"
    ];
    "Mod+Shift+N".action.spawn = [
      "dms"
      "ipc"
      "notepad"
      "toggle"
    ];
    "Mod+Shift+L".action.spawn = [
      "dms"
      "ipc"
      "lock"
    ];

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
}
