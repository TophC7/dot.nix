{ modulesPath, config, pkgs, ... }:

let

  hostname = "proxy";
  admin = "toph";
  password = "[REDACTED]";
  timeZone = "America/New_York";
  defaultLocale = "en_US.UTF-8";

in {

  ## MODULES & IMPORTS ##
  imports = [ 
      # Common Modules
      ../../common/acme
      ../../common/lxc
      ../../common/ssh

      # Import hardware configuration.
      ./hardware.nix

      # Local Modules

      # caddy
      ./modules/caddy
    ];

  ## NETWORKING ##
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ ];
    };
    dhcpcd.enable = false;
    hostName = hostname;
    networkmanager.enable = true;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-net0" = {
      matchConfig.Name = "net0";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  ## PACKAGES ##
  environment.systemPackages = with pkgs; [
    git
    micro
    openssh
    ranger
    sshfs
  ];
}
