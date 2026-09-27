{ pkgs, config, ... }:
{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez-experimental;
    powerOnBoot = true;
    settings = {
      LE = {
        MinConnectionInterval = 16;
        MaxConnectionInterval = 16;
        ConnectionLatency = 10;
        ConnectionSupervisionTimeout = 100;
      };

      Policy = {
        AutoEnable = "true";
      };

      General = {
        Enable = "Source,Sink,Media,Socket";
        FastConnectable = true;
        JustWorksRepairing = "always";
        # Battery info for Bluetooth devices
        Experimental = true;
      };
    };
  };

  boot = {
    extraModprobeConfig = ''
      options bluetooth enable_ecred=1
    '';
  };

  # Automatically unblock Bluetooth on boot to prevent rfkill soft-blocking
  systemd.services.unblock-bluetooth = {
    description = "Unblock Bluetooth rfkill on boot";
    wantedBy = [ "bluetooth.service" ];
    before = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };
}
