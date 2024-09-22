{ modulesPath, config, pkgs, ... }:

let

  hostname = "cloud";

in {
  
  ## MODULES & IMPORTS ##
  imports = [ 
      # Common Modules
      ../../common/lxc
      ../../common/ssh

      # Import hardware configuration.
      ./hardware.nix
      
      # Local Modules
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
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
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
    wget
  ];
}
