{

  wayland.windowManager.hyprland.settings = {

    ## Layers Rules ##

    layer = [
      #"blur, rofi"
      #"ignorezero, rofi"
      #"ignorezero, logout_dialog"
    ];

    ## Window Rules ##

    windowrulev2 = [
      # Dialogs
      "float, title:^(Open File)(.*)$"
      "float, title:^(Select a File)(.*)$"
      "float, title:^(Choose wallpaper)(.*)$"
      "float, title:^(Open Folder)(.*)$"
      "float, title:^(Save As)(.*)$"
      "float, title:^(Library)(.*)$"
      "float, title:^(Accounts)(.*)$"
      "float, title:^(Media viewer)$"

      ## Zen ##
      "suppressevent maximize, class:^(zen)$"
      "float, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "float, class:^(zen)$, title:^(File Upload)$"
      "workspace special silent, title:^(Zen — Sharing Indicator)$"
      "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"

      # Float Apps
      "float, class:^(galculator)$"
      "float, class:^(waypaper)$"
      "float, class:^(keymapp)$"

      # Nautilus
      "float, initialClass:^(org.gnome.Nautilus)$"
      "float, initialClass:^(org.gnome.Nautilus)$, move 10% 50%"
      "size 30% 30%, initialClass:^(org.gnome.Nautilus)$"

      # Always opaque
      "opaque, class:^([Gg]imp)$"
      "opaque, class:^([Ff]lameshot)$"

      "opaque, class:^([Ii]nkscape)$"
      "opaque, class:^([Bb]lender)$"
      "opaque, class:^([Oo][Bb][Ss])$"
      "opaque, class:^([Vv]lc)$"

      # Remove transparency from video
      "opaque, title:^(Netflix)(.*)$"
      "opaque, title:^(.*YouTube.*)$"

      ## Scratch rules ##
      #"size 80% 85%, workspace:^(special:special)$"
      #"center, workspace:^(special:special)$"

      ## Steam rules ##
      "stayfocused, initialClass:^([Gg]amescope)$"
      "fullscreen, initialClass:^([Gg]amescope)$"
      "minsize 1 1, initialClass:^([Gg]amescope)$"
      "immediate, initialClass:^([Gg]amescope)$"
      "workspace 3, initialClass:^([Gg]amescope)$"
      "monitor 0, initialClass:^([Gg]amescope)$"

      #
      # ========== Fameshot rules ==========
      #
      # flameshot currently doesn't have great wayland support so needs some tweaks
      #"rounding 0, class:^([Ff]lameshot)$"
      #"noborder, class:^([Ff]lameshot)$"
      #"float, class:^([Ff]lameshot)$"
      #"move 0 0, class:^([Ff]lameshot)$"
      #"suppressevent fullscreen, class:^([Ff]lameshot)$"
      # "monitor:DP-1, ${flameshot}"

      ## Workspace Assignments ##
      "workspace 1, initialClass:^(vesktop)$"
      "workspace 1, initialClass:^(spotify)$"
      "workspace 1, initialClass:^(org.telegram.desktop)$"
      # "workspace name:4, initialClass:^(virt-manager)$"

      # "workspace 8, class:^(obsidian)$"
      # "workspace 9, class:^(brave-browser)$"
    ];
  };
}
