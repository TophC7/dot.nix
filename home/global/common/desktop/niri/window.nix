{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Niri window rules
  programs.niri = {
    settings = {
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
    };
  };
}
