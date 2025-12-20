{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Niri window rules
  # https://github.com/sodiboo/niri-flake/blob/main/docs.md
  programs.niri = {
    settings = {
      layer-rules = lib.mkDefault [
        # Vicinae search layer (layer-shell surface)
        {
          matches = [
            {
              namespace = "^vicinae$";
            }
          ];
          shadow = {
            enable = true;
            draw-behind-window = true;
          };
        }
      ];

      window-rules = lib.mkDefault [
        {
          geometry-corner-radius = {
            top-left = 8.0;
            top-right = 8.0;
            bottom-left = 8.0;
            bottom-right = 8.0;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
        }

        # Vicinae Launcher
        {
          matches = [
            {
              title = "^Vicinae.*";
              app-id = "";
            }
          ];
          border = {
            enable = true;
            width = 1;
          };
          focus-ring.enable = false;
          clip-to-geometry = true;
        }

        # Settings
        {
          matches = [
            {
              title = "^Settings$";
              app-id = "^org.quickshell$";
            }
            {
              title = "^System Monitor$";
              app-id = "^org.quickshell$";
            }
            {
              title = "^Add Widget$";
              app-id = "^org.quickshell$";
            }
          ];
          open-floating = true;
          default-column-width.proportion = 0.40;
          default-window-height.proportion = 0.60;
        }

        # Code editor
        {
          matches = [
            { app-id = "^code-url-handler$"; }
            { app-id = "^code$"; }
          ];
          default-column-width.proportion = 0.65;
        }

        # Browsers
        {
          matches = [
            { app-id = "^firefox$"; }
            { app-id = "zen-alpha"; }
            { app-id = "zen-beta"; }
            { app-id = "zen"; }
          ];
          excludes = [
            {
              title = "^Extension:.*";
            }
          ];
          default-column-width.proportion = 0.65;
        }

        # Extensions
        {
          matches = [
            {
              title = "^Extension:.*";
            }
          ];
          clip-to-geometry = true;
          open-floating = true;
          open-focused = true;
          default-column-width.proportion = 0.20;
          default-window-height.proportion = 0.40;
        }

        # Communication apps
        {
          matches = [
            { app-id = "^discord$"; }
            { app-id = "^vesktop$"; }
            { app-id = "^org.telegram.desktop$"; }
            { app-id = "^TelegramDesktop$"; }
          ];
          default-column-width.proportion = 1.0;
          open-on-output = "DP-5";
        }

        # File manager
        # Terminal
        {
          matches = [
            { app-id = "^org.gnome.Nautilus$"; }
            { app-id = "^com.mitchellh.ghostty$"; }
            { title = "^ghostty$"; }
          ];
          default-column-width.proportion = 0.40;
          default-window-height.proportion = 0.40;
          open-floating = true;
        }

        # Gaming
        {
          matches = [
            { app-id = "^.gamescope-wrapped$"; }
            { app-id = "^steam_app_.*$"; }
          ];
          default-column-width.proportion = 1.0;
          open-fullscreen = true;
          variable-refresh-rate = true;
        }
      ];
    };
  };
}
