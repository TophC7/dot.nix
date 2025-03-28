{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = lib.custom.scanPaths ./.;

  wayland.windowManager.hyprland = {
    enable = true;
    # withUWSM = true; # One day, but not today
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;

    systemd = {
      enable = true;
      variables = [ "--all" ];
      extraCommands = lib.mkBefore [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };

    plugins = [
      # inputs.hycov.packages.${pkgs.system}.hycov
      (inputs.hyprspace.packages.${pkgs.system}.Hyprspace.overrideAttrs {
        dontUseCmakeConfigure = true;
      })
    ];

    settings = {

      ##  Environment Vars ##
      env = [
        "NIXOS_OZONE_WL, 1" # for ozone-based and electron apps to run on wayland
        "MOZ_ENABLE_WAYLAND, 1" # for firefox to run on wayland
        "MOZ_WEBRENDER, 1" # for firefox to run on wayland
        "XDG_SESSION_TYPE,wayland"
        "WLR_NO_HARDWARE_CURSORS,1"
        "WLR_RENDERER_ALLOW_SOFTWARE,1"
        "QT_QPA_PLATFORM,wayland"
        "HYPRCURSOR_THEME,rose-pine-hyprcursor" # this will be better than default for now
      ];

      ## Monitor ##

      monitor = (
        # INFO: parse the monitors defined in home/<user>/<host>/default.nix
        map (
          m:
          "${m.name},${
            if m.enabled then
              "${toString m.width}x${toString m.height}@${toString m.refreshRate},${toString m.x}x${toString m.y},${toString m.scale},transform,${toString m.transform},vrr,${toString m.vrr}"
            else
              "disable"
          }"
        ) (config.monitors)
      );

      # I love this :)
      # Creates 5 workspaces for all monitors
      workspace =
        let
          json = pkgs.writeTextFile {
            name = "monitors.json";
            text = builtins.toJSON config.monitors;
          };
          parse = pkgs.runCommand "parse-workspaces" { } ''
            mkdir "$out"; ${pkgs.jq}/bin/jq -r '
              [ to_entries[] |
                (.key as $i | .value.name as $name |
                  [ range(0;5) | ($i * 5 + .) as $wsnum |
                    if . == 0 then "\($wsnum), monitor:\($name), default:true, persistent:true"
                    else "\($wsnum), monitor:\($name)" end
                  ]
                )
              ] | flatten
            ' ${json} > "$out/out.json"
          '';
          output = builtins.fromJSON (builtins.readFile "${parse}/out.json");
        in
        output;

      ## Behavior ##

      binds = {
        workspace_center_on = 1;
        movefocus_cycles_fullscreen = false;
      };

      input = {
        follow_mouse = 2;
        mouse_refocus = false;
        kb_options = "fkeys:basic_13-24";
        sensitivity = 0.5;
      };

      cursor = {
        inactive_timeout = 10;
      };

      misc = {
        disable_hyprland_logo = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        #disable_autoreload = true;
        new_window_takes_over_fullscreen = 2;
        middle_click_paste = false;
      };

      group = {
        drag_into_group = 2;
        merge_groups_on_drag = true;
        # col.border_active = "";
        # col.border_inactive = "";
        groupbar = {
          enabled = true;
          height = 12;
        };
      };

      dwindle = {
        pseudotile = false;
        force_split = 0;
        smart_split = true;
        split_bias = 1;
      };

      ## Appearance ##

      general = {
        border_size = 2;
        gaps_in = 6;
        gaps_out = 6;
        "col.inactive_border" = "0x44e3625e";
        "col.active_border" = "0x20e3625e";
        allow_tearing = true; # used to reduce latency and/or jitter in games
        snap = {
          enabled = true;
          window_gap = 6;
        };
      };

      decoration = {
        rounding = 10;
        rounding_power = 4.0;
        active_opacity = 0.90;
        inactive_opacity = 0.80;
        fullscreen_opacity = 1.0;
        blur = {
          enabled = true;
          size = 15;
          passes = 2;
          new_optimizations = true;
          ignore_opacity = true;
          xray = true;
          # noise = 0.15;
          popups = true;
        };
        shadow = {
          enabled = true;
          range = 30;
          render_power = 3;
          scale = 1.0;
          color = "0x66000000";
          color_inactive = "0x66000000";
        };
      };

      animation = [
        "windowsIn,   1,  5   ,default, popin 0%"
        "windowsOut,  1,  5   ,default, popin"
        "windowsMove, 1,  5   ,default, slide"
        "fadeIn,      1,  8   ,default"
        "fadeOut,     1,  8   ,default"
        "fadeSwitch,  1,  8   ,default"
        "fadeShadow,  1,  8   ,default"
        "fadeDim,     1,  8   ,default"
        "border,      1,  10  ,default"
        "workspaces,  1,  5   ,default, slide"
      ];

      ## Auto Launch ##

      exec-once = [
        ''${pkgs.waypaper}/bin/waypaper --restore''
      ];

      ## Layers Rules ##

      layer = [
        #"blur, rofi"
        #"ignorezero, rofi"
        #"ignorezero, logout_dialog"
      ];

      ## Window Rules ##

      windowrule = [
        # Dialogs
        "float, title:^(Open File)(.*)$"
        "float, title:^(Select a File)(.*)$"
        "float, title:^(Choose wallpaper)(.*)$"
        "float, title:^(Open Folder)(.*)$"
        "float, title:^(Save As)(.*)$"
        "float, title:^(Library)(.*)$"
        "float, title:^(Accounts)(.*)$"
      ];

      windowrulev2 = [
        #Zen Extensions
        "suppressevent maximize, class:^(zen)$"

        "float, class:^(galculator)$"
        "float, class:^(waypaper)$"
        "float, class:^(keymapp)$"

        #
        # ========== Always opaque ==========
        #
        "opaque, class:^([Gg]imp)$"
        "opaque, class:^([Ff]lameshot)$"
        "opaque, class:^([Ii]nkscape)$"
        "opaque, class:^([Bb]lender)$"
        "opaque, class:^([Oo][Bb][Ss])$"
        "opaque, class:^([Ss]team)$"
        "opaque, class:^([Ss]team_app_*)$"
        "opaque, class:^([Vv]lc)$"

        # Remove transparency from video
        "opaque, title:^(Netflix)(.*)$"
        "opaque, title:^(.*YouTube.*)$"
        "opaque, title:^(Picture-in-Picture)$"
        #
        # ========== Scratch rules ==========
        #
        #"size 80% 85%, workspace:^(special:special)$"
        #"center, workspace:^(special:special)$"

        #
        # ========== Steam rules ==========
        #
        "stayfocused, title:^()$,class:^([Ss]team)$"
        "minsize 1 1, title:^()$,class:^([Ss]team)$"
        "immediate, class:^([Ss]team_app_*)$"
        "workspace 7, class:^([Ss]team_app_*)$"
        "monitor 0, class:^([Ss]team_app_*)$"

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

        #
        # ========== Workspace Assignments ==========
        #
        # "workspace 8, class:^(virt-manager)$"
        # "workspace 8, class:^(obsidian)$"
        # "workspace 9, class:^(brave-browser)$"
        # "workspace 9, class:^(signal)$"
        # "workspace 9, class:^(org.telegram.desktop)$"
        # "workspace 9, class:^(discord)$"
        # "workspace 0, title:^([Ss]potify*)$"
        # "workspace special, class:^(yubioath-flutter)$"
      ];

      # load at the end of the hyperland set
      # extraConfig = '''';

      plugin = {
      };
    };
  };
}
