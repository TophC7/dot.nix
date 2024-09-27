{ modulesPath, config, pkgs, hostName ... }:
{
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
  ];

  environment.variables = {
    HOSTNAME = hostname;
  };
}
