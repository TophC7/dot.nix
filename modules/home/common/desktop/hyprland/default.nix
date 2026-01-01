{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hyprscrolling = inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprscrolling;
  # hyprspace = inputs.hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace;
in
{
  imports = lib.fs.scanPaths ./.;

  # Hyprland home-manager configuration
  wayland.windowManager.hyprland = {
    enable = true;

    # Use the package from NixOS module (set to null)
    package = null;

    # CRITICAL: Disable systemd integration when using UWSM
    systemd.enable = false;

    # Plugins for niri-like scrolling layout and overview
    plugins = [
      hyprscrolling # Column-based scrolling layout like niri
      # hyprspace # Overview/workspace switcher like GNOME/niri
    ];

    settings = {
      # Input configuration
      input = {
        kb_layout = "us";
        kb_options = "terminate:ctrl_alt_bksp,compose:menu";

        follow_mouse = 2;

        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
        };

        sensitivity = 0;
      };

      # General settings
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        layout = "scrolling"; # Use hyprscrolling for niri-like behavior
      };

      # Hyprscrolling plugin configuration (niri-like scrolling layout)
      plugin = {
        hyprscrolling = {
          column_width = 0.5; # Default column width as fraction of monitor
          explicit_column_widths = "0.333, 0.5, 0.667, 1.0"; # Preset widths for cycling
          fullscreen_on_one_column = false;
          focus_fit_method = 1; # 0 = center, 1 = fit
          follow_focus = true; # Auto-scroll to focused window
        };
      };

      # Decoration
      decoration = {
        rounding = 10;
        rounding_power = 4.0;
        active_opacity = 0.98;
        inactive_opacity = 0.92;
        fullscreen_opacity = 1.0;
        dim_inactive = true;
        dim_strength = 0.2;

        blur = {
          enabled = true;
          size = 5;
          passes = 2;
          new_optimizations = true;
          ignore_opacity = true;
          # xray = true;
          noise = 0.15;
          popups = true;
        };

        shadow = {
          enabled = true;
          range = 30;
          render_power = 2;
          scale = 1.5;
        };
      };

      # Animations - user will customize
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      group = {
        drag_into_group = 2;
        merge_groups_on_drag = true;
        groupbar = {
          enabled = true;
          height = 12;
        };
      };

      # Layout configuration
      dwindle = {
        pseudotile = false;
        force_split = 0;
        smart_split = true;
        split_bias = 1;
      };

      master = {
        new_status = "master";
      };

      # Misc settings
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      # XWayland settings
      xwayland = {
        force_zero_scaling = true;
      };

      # Environment variables
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
      ];

      # Monitor configuration from config.monitors
      monitor = lib.forEach config.monitors (
        m:
        let
          resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
          position = "${toString m.x}x${toString m.y}";
          scale = toString m.scale;
          transform = toString m.transform;
          vrr = if m.vrr or false then ",vrr,1" else "";
        in
        "${m.name},${
          if m.enabled then "${resolution},${position},${scale},transform,${transform}${vrr}" else "disable"
        }"
      );
    };
  };
}
