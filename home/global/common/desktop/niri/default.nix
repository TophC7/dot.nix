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
  # Import program-specific configurations
  imports = [ ./programs ];

  # Essential packages for Niri
  home.packages = with pkgs; [
    wl-clipboard # Clipboard utilities for Wayland
    grim # Screenshot utility
    slurp # Screen area selection tool
    wl-color-picker # Color picker for Wayland
    wf-recorder # Screen recording
    playerctl # Media player control
  ];

  # Niri window manager configuration
  programs.niri = {
    settings = {
      # Input configuration
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

      # Keybindings
      binds = {
        # Application launchers
        "Mod+G".action.spawn = lib.getExe pkgs.ghostty;
        "Mod+E".action.spawn = lib.getExe pkgs.vscode;
        "Mod+W".action.spawn = lib.getExe inputs.zen-browser.packages.${pkgs.system}.default;
        "Mod+F".action.spawn = lib.getExe pkgs.nautilus;

        # DankMaterialShell keybinds
        "Mod+A".action.spawn = [
          "dms"
          "ipc"
          "spotlight"
          "toggle"
        ]; # Application launcher

        "Mod+N".action.spawn = [
          "dms"
          "ipc"
          "notifications"
          "toggle"
        ]; # Notification center

        "Mod+Comma".action.spawn = [
          "dms"
          "ipc"
          "settings"
          "toggle"
        ]; # Settings

        "Mod+M".action.spawn = [
          "dms"
          "ipc"
          "processlist"
          "toggle"
        ]; # Process list (system monitor)

        "Mod+X".action.spawn = [
          "dms"
          "ipc"
          "clipboard"
          "toggle"
        ]; # Clipboard manager (your custom keybind!)

        "Mod+Shift+X".action.spawn = [
          "dms"
          "ipc"
          "powermenu"
          "toggle"
        ]; # Power menu

        "Mod+Shift+P".action.spawn = [
          "dms"
          "ipc"
          "notepad"
          "toggle"
        ]; # Notepad

        "Mod+Alt+N".action.spawn = [
          "dms"
          "ipc"
          "night"
          "toggle"
        ]; # Night mode

        # System controls
        "Mod+Alt+Escape".action.quit = { }; # Exit Niri
        "Ctrl+Alt+Delete".action.spawn = [
          "loginctl"
          "terminate-user"
          "$USER"
        ];
        "Super+Alt+L".action.spawn = [
          "dms"
          "ipc"
          "lock"
          "lock"
        ]; # DMS lock screen (replaces swaylock)
        "Mod+Alt+A".action.toggle-overview = { };
        "Mod+F1".action.show-hotkey-overlay = { };

        # Window/Column management
        "Mod+Q".action.close-window = { };
        "Mod+D".action.center-column = { };
        "Mod+P".action.toggle-window-floating = { }; # Kept (DMS notepad moved to Mod+Shift+P)
        "Mod+S".action.toggle-column-tabbed-display = { }; # Kept (DMS settings moved to Mod+Comma)

        # Window focus
        "Mod+C".action.focus-column-or-monitor-left = { };
        "Mod+B".action.focus-column-or-monitor-right = { };
        "Mod+T".action.focus-window-or-workspace-up = { };
        "Mod+V".action.focus-window-or-workspace-down = { };

        # Window movement
        "Mod+Shift+C".action.consume-or-expel-window-left = { };
        "Mod+Shift+B".action.consume-or-expel-window-right = { };
        "Mod+Shift+T".action.move-window-up = { };
        "Mod+Shift+V".action.move-window-down = { };

        # Monitor/Workspace movement
        "Mod+Ctrl+C".action.move-column-to-monitor-left = { };
        "Mod+Ctrl+B".action.move-column-to-monitor-right = { };
        "Mod+Ctrl+T".action.move-column-to-workspace-up = { };
        "Mod+Ctrl+V".action.move-column-to-workspace-down = { };

        # Window sizing
        "Mod+Alt+C".action.switch-preset-column-width-back = { };
        "Mod+Alt+B".action.switch-preset-column-width = { };
        "Mod+Alt+T".action.set-window-height = "+10%";
        "Mod+Alt+V".action.set-window-height = "-10%";
        "Mod+Alt+F".action.fullscreen-window = { };

        # Screenshots
        "Print".action.screenshot = { };
        "Shift+Print".action.screenshot-screen = { };
        "Alt+Print".action.screenshot-window = { };

        # Media controls (DMS)
        "XF86AudioRaiseVolume".action.spawn = [
          "dms"
          "ipc"
          "audio"
          "increment"
          "3"
        ];

        "XF86AudioLowerVolume".action.spawn = [
          "dms"
          "ipc"
          "audio"
          "decrement"
          "3"
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

        # Media player controls
        "XF86AudioPlay".action.spawn = [
          "${pkgs.playerctl}/bin/playerctl"
          "play-pause"
        ];
        "XF86AudioNext".action.spawn = [
          "${pkgs.playerctl}/bin/playerctl"
          "next"
        ];
        "XF86AudioPrev".action.spawn = [
          "${pkgs.playerctl}/bin/playerctl"
          "previous"
        ];

        # Brightness controls (DMS)
        "XF86MonBrightnessUp".action.spawn = [
          "dms"
          "ipc"
          "brightness"
          "increment"
          "5"
          ""
        ];

        "XF86MonBrightnessDown".action.spawn = [
          "dms"
          "ipc"
          "brightness"
          "decrement"
          "5"
          ""
        ];
      };

      # Window rules
      window-rules = [
        # Code editor
        {
          matches = [
            { app-id = "^code-url-handler$"; }
            { app-id = "^Code$"; }
          ];
          default-column-width = {
            proportion = 1.0;
          };
        }

        # Browsers
        {
          matches = [
            { app-id = "^firefox$"; }
            { app-id = "^zen-alpha$"; }
            { app-id = "^zen$"; }
          ];
          default-column-width = {
            proportion = 0.75;
          };
        }

        # Communication apps
        {
          matches = [
            { app-id = "^discord$"; }
            { app-id = "^org.telegram.desktop$"; }
            { app-id = "^TelegramDesktop$"; }
          ];
          default-column-width = {
            proportion = 1.0;
          };
        }

        # File manager
        {
          matches = [ { app-id = "^org.gnome.Nautilus$"; } ];
          default-column-width = {
            proportion = 0.35;
          };
        }

        # Terminal
        {
          matches = [
            { app-id = "^com.mitchellh.ghostty$"; }
            { title = "^ghostty$"; }
          ];
          default-column-width = {
            proportion = 0.35;
          };
        }

        # Gaming
        {
          matches = [
            { app-id = "^.gamescope-wrapped$"; }
            { app-id = "^steam_app_.*$"; }
          ];
          default-column-width = {
            proportion = 1.0;
          };
          open-fullscreen = true;
        }
      ];

      # Layout configuration
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

        # Tab indicator configuration
        tab-indicator = {
          enable = true;
          position = "left"; # Show on left edge of windows
          width = 4;
          gap = 8;
          hide-when-single-tab = true;
          place-within-column = true;

          # Active window (has keyboard focus) - Bright blue
          active.color = "rgb(94 196 255)";

          # Inactive windows (no keyboard focus) - Gray, semi-transparent
          inactive.color = "rgba(128 128 128 / 0.6)";

          # Urgent windows (requesting attention) - Bright red
          urgent.color = "rgb(255 94 94)";
        };
      };

      overview = {
        backdrop-color = "#000000"; # Semi-transparent black
      };

      # Animations
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

      # Environment variables
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
}
