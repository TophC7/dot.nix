# Waybar - Status bar for Niri (minimal working config)
{ ... }:
{
  programs.waybar = {
    enable = true;

    # Enable systemd integration so it starts automatically
    systemd = {
      enable = true;
      target = "niri.service";
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "niri/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "niri/workspaces" = {
          format = "{icon}";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{:%Y-%m-%d}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            default = [ "" "" "" ];
          };
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };

        tray = {
          spacing = 10;
        };
      };
    };

    # Minimal styling
    style = ''
      * {
        font-family: monospace;
        font-size: 13px;
      }

      window#waybar {
        background: #1e1e1e;
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 8px;
        color: #ffffff;
      }

      #workspaces button.active {
        background: #383838;
      }

      #clock,
      #pulseaudio,
      #network,
      #battery,
      #tray {
        padding: 0 10px;
      }
    '';
  };
}
