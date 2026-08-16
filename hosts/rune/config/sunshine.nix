{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  wayscope = config.home-manager.users.${host.user.name}.programs.wayscope.wrappers;
  steam = lib.getExe config.programs.steam.package;
  steamWayscope = lib.getExe wayscope.steam-wayscope.wrappedPackage;
  setsid = lib.getExe' pkgs.util-linux "setsid";

  virtual-on = pkgs.writeScript "sunshine-virtual-on" ''
    #!${lib.getExe pkgs.fish}
    # Disable physical monitors
    niri msg output DP-3 off
    niri msg output DP-5 off
    # Enable virtual display
    niri msg output HDMI-A-2 on
    sleep 1
    niri msg action focus-monitor HDMI-A-2
  '';

  virtual-off = pkgs.writeScript "sunshine-virtual-off" ''
    #!${lib.getExe pkgs.fish}
    # Disable virtual display
    niri msg output HDMI-A-2 off
    # Re-enable physical monitors
    niri msg output DP-5 on
    niri msg output DP-3 on
    sleep 1
    niri msg action focus-monitor DP-3
  '';

  eden-open = pkgs.writeScript "eden-open" ''
    #!${lib.getExe pkgs.fish}
    niri msg action focus-workspace eden
    niri msg action spawn -- ${lib.getExe pkgs.eden}

    # Wait for eden window to appear (up to 10s)
    set -l attempts 20
    set -l window_id ""
    while test $attempts -gt 0
      # niri msg windows outputs plaintext — parse Window ID before matching App ID
      set -l current_id ""
      for line in (niri msg windows 2>/dev/null)
        if string match -rq '^Window ID (\d+)' -- $line
          set current_id (string match -r '^Window ID (\d+)' -- $line)[2]
        else if string match -rq 'App ID: "dev.eden_emu.eden"' -- $line
          set window_id $current_id
          break
        end
      end
      if test -n "$window_id"
        break
      end
      sleep 0.5
      set attempts (math "$attempts - 1")
    end

    # Focus and fullscreen
    if test -n "$window_id"
      niri msg action focus-window --id $window_id
      niri msg action fullscreen-window
    end
  '';

  eden-close = pkgs.writeScript "eden-close" ''
    #!${lib.getExe pkgs.fish}
    # Force kill eden — graceful close doesn't work reliably
    pkill -9 -x .eden-wrapped
  '';
in
{
  users.users.${host.user.name}.extraGroups = [ "uinput" ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      # output_name left unset — after prep-cmd disables physical monitors,
      # HDMI-A-2 is the only active display so Sunshine auto-selects it.
      # NOTE: KMS capture on Linux expects numeric indexes (0, 1, 2), not connector names.
      capture = "kms";
      encoder = "vaapi";
      adapter_name = "/dev/dri/renderD128";
      hevc_mode = "0";
      av1_mode = "0";
      qp = "20";
      vaapi_strict_rc_buffer = "enabled";
      fec_percentage = "20";
      system_tray = "disabled";
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
              do = steamWayscope;
              undo = "${setsid} ${steam} steam://close/bigpicture";
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
