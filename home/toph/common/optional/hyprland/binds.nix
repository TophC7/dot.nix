{
  config,
  lib,
  pkgs,
  ...
}:
let
  ## Functions, Variables and Launchers ##

  # colorpicker = exec ./scripts/colorpicker.fish;
  # lockscreen = exec ./scripts/lockscreen.fish;
  # notify = exec ./scripts/notify.fish;
  # wlogout = exec ./scripts/wlogout.fish;
  #gtk-play = "${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play";
  #makoctl = "${config.services.mako.package}/bin/makoctl";
  #notify-send = "${pkgs.libnotify}/bin/notify-send";
  #playerctl = lib.getExe pkgs.playerctl; # installed via /home/common/optional/desktops/playerctl.nix
  #swaylock = "lib.getExe pkgs.swaylock;

  defaultApp =
    type: "${pkgs.gtk3}/bin/gtk-launch $(${pkgs.xdg-utils}/bin/xdg-mime query default ${type})";
  exec = script: "${pkgs.fish}/bin/fish ${script}";

  files = "${pkgs.nautilus}/bin/nautilus $HOME";
  browser = defaultApp "x-scheme-handler/https";
  editor = "code";
  launcher = "${pkgs.walker}/bin/walker --modules applications,ssh";
  pactl = lib.getExe' pkgs.pulseaudio "pactl";
  terminal = exec ./scripts/terminal.fish;

  ## Long ass keys ##
  lowerVol = "XF86AudioLowerVolume";
  raiseVol = "XF86AudioRaiseVolume";

  ## Keybinds & Submaps ##

  #INFO: Did this scripts to avoid the shitty hyprland config implementation for nix :)
  submaps = {
    ## Submap: Reset ##
    "" = {
      binds = {
        ## One-Shot Binds ##
        "" = [
          ## Terminal ##
          "SUPER,         T,              exec,              ${terminal}"
          # "SUPER_SHIFT,   T,              exec,              ${terminal}" # Floating
          # "SUPER_ALT,     T,              exec,              ${terminal}" # Select

          ## App Runs ##
          "SUPER,         F,              exec,              ${files}"
          "SUPER,         E,              exec,              ${editor}"
          "SUPER,         W,              exec,              ${browser}"
          "SUPER,         N,              exec,              nm-connection-editor"

          ## Launcher ##
          "SUPER,         SUPER_L,        exec,              ${launcher}"
          # "SUPER,         SUPER_L,        exec,              ${launcher} --app launcher"
          # "SUPER,         P,              exec,              ${launcher} --app color" # Color Picker
          # "SUPER,         V,              exec,              ${launcher} --app clip" # Clipboard
          # "SUPER,         X,              exec,              ${launcher} --app power" # Power Menu

          ## System ##
          "SUPER,         L,              exec,              hyprlock"
          # "SUPER,         L,              exec,              ${lockscreen}"
          "SUPER,         Q,              killactive,"
          "CTRL_ALT,      Delete,         exit,"

          ## Window Management ##
          "SUPER_SHIFT,   F,              fullscreen,        0"
          # "SUPER,         F,              exec,              ${notify} 'Fullscreen Mode'"
          "SUPER,         Backspace,      togglefloating,"
          "SUPER,         Backspace,      centerwindow,"
          "SUPER,         left,           scroller:movefocus,         l"
          "SUPER,         right,          scroller:movefocus,         r"
          "SUPER,         up,             scroller:movefocus,         u"
          "SUPER,         down,           scroller:movefocus,         d"
          "SUPER_SHIFT,   left,           scroller:movewindow,        l,            nomode"
          "SUPER_SHIFT,   right,          scroller:movewindow,        r,            nomode"
          "SUPER_SHIFT,   up,             scroller:movewindow,        u,            nomode"
          "SUPER_SHIFT,   down,           scroller:movewindow,        d,            nomode"
          "SUPER_SHIFT,   P,              pin,"
          # "SUPER_SHIFT,   P,              exec,              ${notify} 'Toggled Pin'"
          "SUPER_SHIFT,   S,              swapnext"
          # "SUPER_SHIFT,   O,              toggleopaque"
          "SUPER,         G,              togglegroup"
          # "SUPER,         G,              exec,              ${notify} 'Toggled Group'"
          "SUPER,         Tab,            changegroupactive, f"

          # ## Workspaces ##
          # ",              Home,           hyprexpo:expo,              toggle"
          ",              Home,           overview:toggle"
          "ALT,           Tab,            cyclenext,"
          "ALT,           Tab,            bringactivetotop,"
          "SUPER_ALT,     G,              submap,                     steam"

          ## Scroller ##
          "SUPER,         P,              scroller:pin"
          "SUPER,         P,              scroller:alignwindow,       left"
          "SUPER,         P,              scroller:setsize,           onethird"
          # "\\notify"
          "SUPER_SHIFT,   P,              scroller:pin"
          "SUPER_SHIFT,   P,              scroller:alignwindow,       right"
          "SUPER_SHIFT,   P,              scroller:setsize,           onethird"
          # "\\notify"
          "SUPER,         A,              scroller:jump"
          # F20 - F23
          ",         code:198,            scroller:selectiontoggle"
          ",         code:199,            scroller:selectionworkspace"
          ",         code:200,            scroller:selectionmove,     e"
          ",         code:201,            scroller:selectionreset"

        ];

        ## Repeating Binds ##
        e = [
          "SUPER_ALT,     left,           scroller:cyclewidth,        next"
          "SUPER_ALT,     right,          scroller:cyclewidth,        prev"
          "SUPER_ALT,     up,             scroller:cycleheight,       next"
          "SUPER_ALT,     down,           scroller:cycleheight,       prev"
          # "SUPER_ALT,     left,           resizeactive,    -20    0"
          # "SUPER_ALT,     right,          resizeactive,     20    0"
          # "SUPER_ALT,     up,             resizeactive,     0    -20"
          # "SUPER_ALT,     down,           resizeactive,     0     20"
          ",              ${raiseVol},    exec,             ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
          ",              ${lowerVol},    exec,             ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
          ",              ${raiseVol},    exec,             ${pactl} set-source-volume @DEFAULT_SOURCE@ +5%"
          ",              ${lowerVol},    exec,             ${pactl} set-source-volume @DEFAULT_SOURCE@ -5%"
        ];

        ## Mouse Binds ##
        m = [
          ",              mouse:275,      movewindow"
          ",              mouse:276,      resizewindow"
        ];
      };
    };

    ## Submap: Steam ##
    steam = {
      binds = {
        "" = [
          "SUPER,         Escape,         submap,           reset"
          "SUPER,         SUPER_L,        pass"
          ",              mouse:275,      pass"
          ",              mouse:276,      pass"
        ];
      };
    };
  };

  submaps-json = pkgs.writeText "submaps.json" (builtins.toJSON submaps);
  submaps-script = pkgs.writeScript "submap-script" ''
    #!/usr/bin/env fish

    # Usage: ./parse_submaps.fish path/to/file.json
    if test (count $argv) -lt 1
        echo "Usage: $argv[0] path/to/file.json"
        exit 1
    end

    set json_file $argv[1]

    # Iterate over submaps preserving order
    for entry in (${pkgs.jq}/bin/jq -c '.| to_entries[]' $json_file)
        set submap_name (echo $entry | ${pkgs.jq}/bin/jq -r '.key')
        echo "submap=$submap_name"
        
        # Process each binds entry within the submap
        for bind_entry in (echo $entry | ${pkgs.jq}/bin/jq -c '.value.binds | to_entries[]')
            set bind_key (echo $bind_entry | ${pkgs.jq}/bin/jq -r '.key')
            
            if test "$bind_key" = ""
                set prefix "bind="
            else if test "$bind_key" = "unbind"
                set prefix "unbind="
            else
                set prefix "bind$bind_key="
            end

            # Process each binding's value in the array
            for binding in (echo $bind_entry | ${pkgs.jq}/bin/jq -r '.value[]')
                echo "$prefix$binding"
            end
        end

        # Append submap reset except for default "" submap
        if not test "$submap_name" = ""
            echo "submap=reset"
        end
    end
  '';
  submaps-run = pkgs.runCommand "submaps-run" { inherit submaps-json submaps-script; } ''
    mkdir -p $out
    ${pkgs.fish}/bin/fish ${submaps-script} ${submaps-json} > $out/submaps-out
  '';
in
{
  wayland.windowManager.hyprland.extraConfig = builtins.readFile "${submaps-run}/submaps-out";
}
