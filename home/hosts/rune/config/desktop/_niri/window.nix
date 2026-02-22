# Niri window rules
# https://github.com/sodiboo/niri-flake/blob/main/docs.md
{ ... }:
{
  programs.niri = {
    settings = {
      layer-rules = [
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

      window-rules = [
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

        # File manager & Terminal
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

        # Common dialogs
        {
          matches = [
            { title = "^(Open|Save|File|Folder).*$"; }
            { title = "^(Open File|Save File|Save As).*$"; }
            { app-id = "^org\\.gnome\\.Calculator$"; }
            { app-id = "^pavucontrol$"; }
            { app-id = "^nm-connection-editor$"; }
            { app-id = "^blueman-manager$"; }
            { app-id = "^xdg-desktop-portal.*$"; }
          ];
          open-floating = true;
        }

        # Proton Pass
        {
          matches = [
            { app-id = "^Proton Pass$"; }
          ];
          open-floating = true;
          default-column-width.fixed = 1080;
          default-window-height.fixed = 960;
        }

        # Proton Authenticator
        {
          matches = [
            { app-id = "^proton-authenticator$"; }
          ];
          open-floating = true;
          default-column-width.fixed = 1080;
          default-window-height.fixed = 960;
        }

        # Picture-in-Picture
        {
          matches = [
            { title = "^Picture.in.Picture$"; }
            { title = "^Picture in Picture$"; }
          ];
          open-floating = true;
          default-column-width.fixed = 640;
          default-window-height.fixed = 360;
        }

        # Gaming
        {
          matches = [
            { app-id = "^\\.?gamescope"; } # gamescope & .gamescope-wrapped
            { app-id = "^steam_app_"; } # All Steam app windows
            { app-id = "\\.exe$"; } # All Wine/Proton .exe windows
            { app-id = "^HytaleClient$"; }
          ];
          default-column-width.proportion = 1.0;
          open-fullscreen = true;
          variable-refresh-rate = true;
          inhibit-shortcuts = true;
        }
      ];
    };
  };
}
