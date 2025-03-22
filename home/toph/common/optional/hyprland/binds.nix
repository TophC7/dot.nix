{
  config,
  lib,
  pkgs,
  ...
}:
{
  #INFO: Reference bind flags: https://wiki.hyprland.org/Configuring/Binds/#bind-flags
  wayland.windowManager.hyprland.settings =
    let
      # -- Functions --
      defaultApp =
        type: "${pkgs.gtk3}/bin/gtk-launch $(${pkgs.xdg-utils}/bin/xdg-mime query default ${type})";
      exec = script: "${pkgs.fish}/bin/fish ${script}";
      xdg-open = command: "${pkgs.xdg-utils}/bin/xdg-open ${command}";

      # -- Script Launchers --
      # colorpicker = exec ./scripts/colorpicker.fish;
      # lockscreen = exec ./scripts/lockscreen.fish;
      # notify = exec ./scripts/notify.fish;
      terminal = exec ./scripts/terminal.fish;
      # wlogout = exec ./scripts/wlogout.fish;

      # -- Commands or Binaries --
      browser = defaultApp "x-scheme-handler/https";
      editor = "code";
      menu = "${pkgs.walker}/bin/walker --modules applications,ssh";
      files = xdg-open "$HOME";
      pactl = lib.getExe' pkgs.pulseaudio "pactl";

      #playerctl = lib.getExe pkgs.playerctl; # installed via /home/common/optional/desktops/playerctl.nix
      #swaylock = "lib.getExe pkgs.swaylock;
      #makoctl = "${config.services.mako.package}/bin/makoctl";
      #gtk-play = "${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play";
      #notify-send = "${pkgs.libnotify}/bin/notify-send";

      # This shits too long
      lowerVol = "XF86AudioLowerVolume";
      raiseVol = "XF86AudioRaiseVolume";
    in
    {
      ## Mouse Binds ##
      bindm = [
        ",              mouse:275,      movewindow"
        ",              mouse:276,      resizewindow"
      ];

      ## Non-consuming Binds  ##
      bindn = [
      ];

      ## Repeat Binds ##
      binde = [
        # Resize active window 5 pixels in direction
        "SUPER_ALT,     left,           resizeactive,    -20    0"
        "SUPER_ALT,     right,          resizeactive,     20    0"
        "SUPER_ALT,     up,             resizeactive,     0    -20"
        "SUPER_ALT,     down,           resizeactive,     0     20"

        # -- Volume --
        ",              ${raiseVol},    exec,              ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
        ",              ${lowerVol},    exec,              ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
        ",              ${raiseVol},    exec,              ${pactl} set-source-volume @DEFAULT_SOURCE@ +5%"
        ",              ${lowerVol},    exec,              ${pactl} set-source-volume @DEFAULT_SOURCE@ -5%"
      ];

      ## One-shot Binds ##
      bind = [
        # -- Terminal --
        "SUPER,         T,              exec,              ${terminal}"
        "SUPER_SHIFT,   T,              exec,              ${terminal}" # floating
        "SUPER_ALT,     T,              exec,              ${terminal}" # select size?

        # -- Apps --
        "SUPER,         F,              exec,              ${files}"
        "SUPER,         E,              exec,              ${editor}"
        "SUPER,         W,              exec,              ${browser}"
        "SUPER,         N,              exec,              nm-connection-editor"
        # "SUPER,         P,              exec,              ${colorpicker}"

        # -- Menu --
        "SUPER,         SUPER_L,        exec,              ${menu}"
        # "SUPER,         V,              exec,              ${menu}"

        # -- System --
        # "SUPER,         X,              exec,              ${wlogout}"
        # "SUPER,         L,              exec,              ${lockscreen}"
        "SUPER,         L,              exec,              hyprlock"
        "SUPER,         Q,              killactive,"
        "CTRL_ALT,      Delete,         exit,"

        # -- Window Management --
        "SUPER_SHIFT,   F,              fullscreen,        0"
        # "SUPER,         F,              exec,              ${notify} 'Fullscreen Mode'"
        "SUPER,         Backspace,      togglefloating,"
        "SUPER,         Backspace,      centerwindow,"
        "SUPER,         left,           movefocus,         l"
        "SUPER,         right,          movefocus,         r"
        "SUPER,         up,             movefocus,         u"
        "SUPER,         down,           movefocus,         d"
        "SUPER_SHIFT,   left,           movewindow,        l"
        "SUPER_SHIFT,   right,          movewindow,        r"
        "SUPER_SHIFT,   up,             movewindow,        u"
        "SUPER_SHIFT,   down,           movewindow,        d"
        "SUPER_SHIFT,   P,              pin,"
        # "SUPER_SHIFT,   P,              exec,              ${notify} 'Toggled Pin'"
        "SUPER_SHIFT,   S,              swapnext"
        # "SUPER_SHIFT,   O,              toggleopaque"

        # -- Workspaces --
        ",              Home,           overview:toggle"
        # "SUPER,         A,              "
        # TODO:  use hycov for alt tab, https://github.com/bighu630/hycov
        "ALT,         Tab,            cyclenext,"
        "ALT,         Tab,            bringactivetotop,"
      ];

    };
}
