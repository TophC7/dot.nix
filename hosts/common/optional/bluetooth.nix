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
      # make Xbox Series X controller work
      General = {
        Enable = "Source,Sink,Media,Socket";
        FastConnectable = true;
        JustWorksRepairing = "always";
        # Battery info for Bluetooth devices
        Experimental = true;
      };
    };
  };

  services.blueman.enable = true;
  # these 2 options below were not mentioned in wiki

  boot = {
    extraModprobeConfig = ''
      options bluetooth enable_ecred=1
    '';
  };

  environment.systemPackages = with pkgs; [
    bluez-tools
    bluetuith # can transfer files via OBEX
  ];
}
