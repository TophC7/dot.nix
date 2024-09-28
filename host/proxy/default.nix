{ modulesPath, config, pkgs, hostName, ... }:
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
      ./modules/cloudflared
    ];

  ## NETWORKING ##
  networking.firewall = {
    allowedTCPPorts = [ 22 80 443 14333 ];
    allowedUDPPorts = [ 53 ];
    interfaces.podman1 = {
      # so that containers find eachother's names
      allowedUDPPorts = [ 53 ]; 
    };
  };

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
    git
    micro
    openssh
    ranger
    sshfs
  ];
  
  environment.etc = {
    "cloudflared/.keep" = {
      text = "This directory is used to store cloudflared configuration files.";
    };
  };

  environment.variables = {
    HOSTNAME = hostName;
  };

  ## PROGRAMS & SERVICES ##
  # Enable podman
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
}
