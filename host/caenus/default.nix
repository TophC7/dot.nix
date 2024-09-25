{ modulesPath, config, pkgs, ... }:

let

  hostname = "caenus";

in {
  
  ## MODULES & IMPORTS ##

  imports =
    [ 
      # FRP
      ./modules/frp
      # Nginx
      ./modules/nginx
      # Include the results of the hardware scan.
      ./hardware.nix
    ];

  ## BOOTLOADER ##

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  ## NETWORKING ##
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 80 443 4040 ];
      allowedUDPPorts = [ 25565 4040 ];
    };
    dhcpcd.enable = false;
    hostName = hostname;
    networkmanager.enable = true;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-enp0s6" = {
      matchConfig.Name = "enp0s6";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
    git
    micro
    openssh
    ranger
    sshfs
    wget
  ];
  
  environment.variables = {
    HOSTNAME = hostname;
  };
}
