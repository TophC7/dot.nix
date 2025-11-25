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
              title = "^Extension$";
            }
          ];
          default-column-width = {
            proportion = 0.75;
          };
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
        }
      ];
    };
  };
}
