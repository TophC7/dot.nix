{ pkgs, lib, ... }:
let
  # NOTE: This is a bit hacky, and will need to be refactored with any monitor changes. But its a simpler solution.
  virtual-on = pkgs.writeScript "sunshine-virtual-on" ''
    #!${lib.getExe pkgs.fish}
    # Disable physical monitors
    hyprctl keyword monitor "DP-3, disable"
    hyprctl keyword monitor "DP-5, disable"
    # Enable virtual display at 2K@60
    hyprctl keyword monitor "HDMI-A-2, 2560x1440@60, 0x0, 1"
    sleep 1
    hyprctl dispatch focusmonitor HDMI-A-2
  '';

  virtual-off = pkgs.writeScript "sunshine-virtual-off" ''
    #!${lib.getExe pkgs.fish}
    # Disable virtual display
    hyprctl keyword monitor "HDMI-A-2, disable"
    # Re-enable physical monitors
    hyprctl keyword monitor "DP-5, 1920x1080@60, 0x0, 1, transform, 3"
    hyprctl keyword monitor "DP-3, 3840x2160@120, 1080x0, 1"
    sleep 1
    hyprctl dispatch focusmonitor DP-3
  '';

  eden-open = pkgs.writeScript "eden-open" ''
    #!${lib.getExe pkgs.fish}
    hyprctl keyword windowrulev2 "workspace name:eden silent, class:dev.eden_emu.eden"
    hyprctl dispatch workspace name:eden
    hyprctl dispatch exec ${lib.getExe pkgs.eden}

    # Wait for eden window to appear (up to 10s)
    set -l attempts 20
    while test $attempts -gt 0
      if hyprctl clients -j | grep -q "dev.eden_emu.eden"
        break
      end
      sleep 0.5
      set attempts (math "$attempts - 1")
    end

    # Focus and fullscreen
    hyprctl dispatch focuswindow class:dev.eden_emu.eden
    hyprctl dispatch fullscreen 2
  '';

  eden-close = pkgs.writeScript "eden-close" ''
    #!${lib.getExe pkgs.fish}
    hyprctl dispatch closewindow class:dev.eden_emu.eden

    set -l timeout 30
    while test $timeout -gt 0
      if not pgrep -x eden >/dev/null
        exit 0
      end
      sleep 1
      set timeout (math "$timeout - 1")
    end

    kill -9 (pgrep -x eden)
  '';
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      output_name = "HDMI-A-2";
    };

    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.local/bin";
      };

      apps = [
        {
          name = "Desktop";
          prep-cmd = [
            {
              do = "${virtual-on}";
              undo = "${virtual-off}";
            }
          ];
          image-path = "desktop.png";
        }
        {
          name = "Steam Big Picture";
          prep-cmd = [
            {
              do = "${virtual-on}";
              undo = "${virtual-off}";
            }
            {
              do = "steam-wayscope";
              undo = "setsid steam steam://close/bigpicture";
            }
          ];
          image-path = "steam.png";
        }
        {
          name = "Eden";
          prep-cmd = [
            {
              do = "${virtual-on}";
              undo = "${virtual-off}";
            }
            {
              do = "${eden-open}";
              undo = "${eden-close}";
            }
          ];
          output = "/home/toph/.local/state/sunshine/log/eden.log";
          image-path = "/home/toph/.local/state/sunshine/eden.png";
        }
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/toph/.local/state/sunshine/log 0755 toph users -"
  ];
}
