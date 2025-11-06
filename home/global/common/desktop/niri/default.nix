# Niri Window Manager Configuration
# Core Niri settings only - programs split into programs/ folder
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  programs.niri = {
    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            options = "terminate:ctrl_alt_bksp,lv3:ralt_switch,compose:menu";
          };
        };

        touchpad = {
          tap = true;
          natural-scroll = true;
          dwt = true; # Disable while typing
        };

        mouse = {
          natural-scroll = false;
        };
      };

      # Prefer no server-side decorations
      prefer-no-csd = true;

      layout = {
        gaps = 8;
        center-focused-column = "never";

        preset-column-widths = [
          { proportion = 0.25; }
          { proportion = 0.35; }
          { proportion = 0.5; }
          { proportion = 0.65; }
          { proportion = 0.90; }
        ];

        default-column-width = {
          proportion = 0.5;
        };

        focus-ring = {
          enable = true;
          width = 4;
        };

        tab-indicator = {
          enable = true;
          position = "left"; # Show on left edge of windows
          width = 4;
          gap = 8;
          hide-when-single-tab = true;
          place-within-column = true;
        };
      };

      animations = {
        enable = true;
        slowdown = 1.0;

        window-open = {
          enable = true;
          kind = {
            easing = {
              curve = "ease-out-quad";
              duration-ms = 150;
            };
          };
        };

        window-close = {
          enable = true;
          kind = {
            easing = {
              curve = "ease-out-quad";
              duration-ms = 150;
            };
          };
        };

        window-movement = {
          enable = true;
          kind = {
            spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };
          };
        };

        workspace-switch = {
          enable = true;
          kind = {
            spring = {
              damping-ratio = 1.0;
              stiffness = 1000;
              epsilon = 0.0001;
            };
          };
        };
      };

      environment = {
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };

      # Screenshot configuration
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # Outputs - dynamically configured from monitors option
      outputs =
        let
          # Convert transform number to Niri rotation (integer degrees)
          # 0 = normal, 1 = 90° CCW, 2 = 180°, 3 = 270° CCW
          transformToRotation =
            t:
            if t == 0 then
              0
            else if t == 1 then
              90
            else if t == 2 then
              180
            else if t == 3 then
              270
            else
              0;
        in
        lib.listToAttrs (
          lib.forEach config.monitors (
            monitor:
            lib.nameValuePair monitor.name {
              enable = monitor.enabled;
              mode = {
                width = monitor.width;
                height = monitor.height;
                # Convert integer to float by adding 0.0
                refresh = monitor.refreshRate + 0.0;
              };
              position = {
                x = monitor.x;
                y = monitor.y;
              };
              scale = monitor.scale;
              transform.rotation = transformToRotation monitor.transform;
              variable-refresh-rate = monitor.vrr or false;
            }
          )
        );
    };
  };

  # Post-process the generated config to add dms includes we cant add otherwise
  # This runs after Home Manager generates the config file
  home.activation.niriConfigPostProcess = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_file="$HOME/.config/niri/config.kdl"

    if [ -f "$config_file" ]; then
      # Create a temporary file with the include statement
      tmpfile=$(mktemp)

      # Add the include at the top, then append the original config
      {
        echo 'include "dms/colors.kdl"'
        echo ""
        cat "$config_file"
      } > "$tmpfile"

      # Replace the original config with our modified version
      mv "$tmpfile" "$config_file"

      $DRY_RUN_CMD echo "Added colors.kdl include to Niri config"
    fi
  '';
}
