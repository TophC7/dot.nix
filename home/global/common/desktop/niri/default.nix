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
        "Mod+T".action.spawn = lib.getExe pkgs.ghostty;
        "Mod+E".action.spawn = lib.getExe pkgs.vscode;
        "Mod+W".action.spawn = lib.getExe inputs.zen-browser.packages.${pkgs.system}.default;
        "Mod+F".action.spawn = lib.getExe pkgs.nautilus;
        "Mod+A".action.spawn = lib.getExe pkgs.fuzzel;

        # System controls
        "Mod+Alt+Escape".action.quit = { }; # Exit Niri
        "Ctrl+Alt+Delete".action.spawn = [
          "loginctl"
          "terminate-user"
          "$USER"
        ];
        "Mod+L".action.spawn = lib.getExe pkgs.swaylock;

        # Window management
        "Mod+Q".action.close-window = { };
        "Mod+C".action.center-column = { };

        # Window focus
        "Mod+Left".action.focus-column-left = { };
        "Mod+Down".action.focus-window-down = { };
        "Mod+Up".action.focus-window-up = { };
        "Mod+Right".action.focus-column-right = { };

        # Window movement
        "Mod+Shift+Left".action.move-column-left = { };
        "Mod+Shift+Down".action.move-window-down = { };
        "Mod+Shift+Up".action.move-window-up = { };
        "Mod+Shift+Right".action.move-column-right = { };

        # Monitor movement
        "Mod+Ctrl+Left".action.move-column-to-monitor-left = { };
        "Mod+Ctrl+Right".action.move-column-to-monitor-right = { };
        "Mod+Ctrl+Up".action.move-column-to-monitor-up = { };
        "Mod+Ctrl+Down".action.move-column-to-monitor-down = { };

        # Window sizing
        "Mod+Alt+Right".action.set-column-width = "+10%";
        "Mod+Alt+Left".action.set-column-width = "-10%";
        "Mod+Alt+Up".action.set-window-height = "+10%";
        "Mod+Alt+Down".action.set-window-height = "-10%";

        # Workspace navigation
        "Mod+Page_Up".action.focus-workspace-up = { };
        "Mod+Page_Down".action.focus-workspace-down = { };

        # Workspace switching by number
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        # Move window to workspace
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;

        # Move window to adjacent workspace
        "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
        "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };

        # Layout controls
        "Mod+Shift+F".action.fullscreen-window = { };
        "Mod+M".action.maximize-column = { };

        # Screenshots
        "Print".action.screenshot = { };
        "Shift+Print".action.screenshot-screen = { };
        "Alt+Print".action.screenshot-window = { };

        # Media controls
        "XF86AudioRaiseVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "5%+"
        ];
        "XF86AudioLowerVolume".action.spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "5%-"
        ];
        "XF86AudioMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
        "XF86AudioMicMute".action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
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

        # Brightness controls (handled by brightness.nix)
        "XF86MonBrightnessUp".action.spawn = [
          "brightness"
          "+"
          "10"
        ];
        "XF86MonBrightnessDown".action.spawn = [
          "brightness"
          "-"
          "10"
        ];

        # Clipboard manager
        "Mod+V".action.spawn = [
          "sh"
          "-c"
          "${lib.getExe pkgs.cliphist} list | ${lib.getExe pkgs.fuzzel} --dmenu | ${lib.getExe pkgs.cliphist} decode | ${lib.getExe pkgs.wl-clipboard}/bin/wl-copy"
        ];

        # Color picker
        "Mod+Ctrl+C".action.spawn = "${lib.getExe pkgs.wl-color-picker}";

        # Notification center
        "Mod+S".action.spawn = [
          "${pkgs.mako}/bin/makoctl"
          "invoke"
        ];

        # Screen recording
        "Mod+Shift+R".action.spawn = [
          "sh"
          "-c"
          "${pkgs.wf-recorder}/bin/wf-recorder -g \"$(${pkgs.slurp}/bin/slurp)\""
        ];

        # Floating toggle
        "Mod+Backspace".action.toggle-window-floating = { };

        # Alt-tab
        "Alt+Tab".action.focus-window-down-or-column-right = { };
        "Alt+Shift+Tab".action.focus-window-up-or-column-left = { };

        # Column management
        "Mod+Comma".action.consume-window-into-column = { };
        "Mod+Period".action.expel-window-from-column = { };
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
            proportion = 0.65;
          };
        }

        # Terminal
        {
          matches = [
            { app-id = "^com.mitchellh.ghostty$"; }
            { title = "^ghostty$"; }
          ];
          default-column-width = {
            proportion = 0.5;
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
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66666; }
          { proportion = 0.75; }
        ];

        default-column-width = {
          proportion = 0.5;
        };

        focus-ring = {
          enable = true;
          width = 4;
        };

        border = {
          enable = true;
          width = 2;
        };
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
      };

      # Screenshot configuration
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # Outputs - auto-detected
      outputs = { };
    };
  };
}
