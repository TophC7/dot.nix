{ pkgs, ... }:
let
  # Zen extensions to float
  zen-script = import ./scripts/zen-float.nix { inherit pkgs; };
  zen-json = pkgs.writeText "zen-extensions.json" (builtins.toJSON zen-extensions);
  zen-extensions = {
    bitwarden = {
      regex = "'*(Bitwarden Password Manager) - Bitwarden*'";
      x = 500;
      y = 900;
    };
    authenticator = {
      regex = "'*(Authenticator) - Authenticator*'";
      x = 335;
      y = 525;
    };
  };
in
{
  wayland.windowManager.hyprland.settings = {

    # Floats zen extensions
    exec-once = [
      "${pkgs.fish}/bin/fish ${zen-script} ${zen-json}"
    ];

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

      # Zen
      "suppressevent maximize, class:^(zen)$"
      "float, initialTitle:^(Picture-in-Picture)$"
      "nodim, initialTitle:^(Picture-in-Picture)$"
      "keepaspectratio, initialTitle:^(Picture-in-Picture)$"
      "float, class:^(zen)$, title:^(File Upload)$"
      "workspace special silent, title:^(Zen — Sharing Indicator)$"
      "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"

      # Foot
      "plugin:scroller:modemodifier col after focus, class:^(foot)$"
      "plugin:scroller:windowheight onethird, class:^(foot)$"

      # Vesktop
      "workspace 2, class:^(vesktop)$"
      "plugin:scroller:group vesktop, class:^(vesktop)$"
      "opaque, initialTitle:^(Discord Popout)$"
      "plugin:scroller:modemodifier row before focus, initialTitle:^(Discord Popout)$"
      "plugin:scroller:windowheight onethird, initialTitle:^(Discord Popout)$"

      # VsCode
      "plugin:scroller:group code, class:^(code)$"
      "plugin:scroller:alignwindow center, class:^(code)$"
      "plugin:scroller:windowheight seveneighths, class:^(code)$"

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

      #Ryujinx
      "opaque, initialClass:^(Ryujinx)$"
      "immediate, initialClass:^(Ryujinx)$"
      "workspace 3, initialClass:^(Ryujinx)$"
      "float, initialTitle:^(ContentDialogOverlayWindow)$"
      "center, initialTitle:^(ContentDialogOverlayWindow)$"

      ## Steam rules ##
      "opaque, initialClass:^([Gg]amescope)$"
      # "stayfocused, initialClass:^([Gg]amescope)$"
      "fullscreen, initialClass:^([Gg]amescope)$"
      "minsize 1 1, initialClass:^([Gg]amescope)$"
      "immediate, initialClass:^([Gg]amescope)$"
      "workspace 3, initialClass:^([Gg]amescope)$"

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
      "workspace 2, initialClass:^(spotify)$"
      "workspace 2, initialClass:^(org.telegram.desktop)$"
      # "workspace name:4, initialClass:^(virt-manager)$"

      # "workspace 8, class:^(obsidian)$"
      # "workspace 9, class:^(brave-browser)$"
    ];
  };
}
