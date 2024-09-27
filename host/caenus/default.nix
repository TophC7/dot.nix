{ modulesPath, config, pkgs, hostName, ... }:
{
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
  networking.firewall = {
    allowedTCPPorts = [ 22 80 443 4040 ];
    allowedUDPPorts = [ 25565 4040 ];
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
    HOSTNAME = hostName;
  };
}
