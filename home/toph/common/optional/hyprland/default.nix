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
    systemd.enable = false; # using withUWSM
    package = null;
    portalPackage = null;

    # systemd = {
    #   enable = true;
    #   variables = [ "--all" ];
    #   extraCommands = lib.mkBefore [
    #     "systemctl --user stop graphical-session.target"
    #     "systemctl --user start hyprland-session.target"
    #   ];
    # };

    settings = {
      ##  Environment Vars ##
      env = [
        "NIXOS_XDG_OPEN_USE_PORTAL, 1" # for xdg-open to use portal
        "NIXOS_OZONE_WL, 1" # for ozone-based and electron apps to run on wayland
        "MOZ_ENABLE_WAYLAND, 1" # for firefox to run on wayland
        "MOZ_WEBRENDER, 1" # for firefox to run on wayland
        "XDG_SESSION_TYPE, wayland"
        "XDG_SESSION_DESKTOP, Hyprland"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "WLR_NO_HARDWARE_CURSORS, 1"
        "WLR_RENDERER_ALLOW_SOFTWARE, 1"
        "QT_QPA_PLATFORM, wayland"
        "GTK_USE_PORTAL, 1"
        "HYPRCURSOR_THEME, rose-pine-hyprcursor" # this will be better than default for now
      ];

      xwayland = {
        force_zero_scaling = true;
      };

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

      # This used to be usefull now its just overkill
      # Creates 1 persistent workspaces for all monitors
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
                  [ range(1;2) | ($i * 1 + .) as $wsnum |
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
        layout = "scroller";
        border_size = 2;
        gaps_in = 6;
        gaps_out = 6;
        # "col.inactive_border" = "rgb(191b1c)";
        # "col.active_border" = "rgb(1cbdd9) rgb(f6ef9d) 30deg";
        allow_tearing = true; # used to reduce latency and/or jitter in games
        snap = {
          enabled = true;
          window_gap = 6;
        };
      };

      decoration = {
        rounding = 10;
        rounding_power = 4.0;
        active_opacity = 0.85;
        inactive_opacity = 0.75;
        fullscreen_opacity = 1.0;
        dim_inactive = true;
        dim_strength = 0.2;
        blur = {
          enabled = true;
          size = 7;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
          xray = true;
          # noise = 0.15;
          popups = true;
        };
        shadow = {
          enabled = true;
          range = 30;
          render_power = 2;
          scale = 1.5;
          # color = "rgb(191b1c)";
          # color_inactive = "rgb(191b1c)";
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
    };
  };
}
