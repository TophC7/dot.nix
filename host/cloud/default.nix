{ modulesPath, config, pkgs, ... }:

let

  hostname = "cloud";

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

      # cron
      ./modules/cron
      # Logrotate
      ./modules/logrotate
      # Nextcloud
      ./modules/nextcloud
      # Nginx
      ./modules/nginx
      # Snapraid-runner
      ./modules/snapraid
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

  ## ENVIORMENT & PACKAGES ##
  nixpkgs.overlays = [ (import ./overlays) ];
  environment.systemPackages = with pkgs; [
    git
    mergerfs
    micro
    openssh
    ranger
    sshfs
    snapraid
    snapraid-runner 
    wget 
  ];
  
  environment.variables = {
    HOSTNAME = hostname;
  };
}
