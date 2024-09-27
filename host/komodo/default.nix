{ modulesPath, config, pkgs, hostName ... }:
{
  ## MODULES & IMPORTS ##
  imports = [ 
      # Common Modules
      ../../common/lxc
      ../../common/ssh

      # Import hardware configuration.
      ./hardware.nix
      
      # Local Modules
      ./modules/frp
      ./modules/komodo
    ];
  
  ## NETWORKING ##
  networking.firewall = {
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ ];
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
