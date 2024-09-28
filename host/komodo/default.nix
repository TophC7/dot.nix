{ modulesPath, config, pkgs, hostName, ... }:
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
    allowedTCPPorts = [ 22 80 443 9120 ];
    allowedUDPPorts = [ ];
    interfaces.podman1 = {
      # so that containers find eachother's names
      allowedUDPPorts = [ 53 ]; 
    };
  };

  systemd.services.create-wordpress-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [
      "${backend}-komodo.service"
      "${backend}-mongo.service" 
      "${backend}-periphery.service"
    ];
    script = ''
      ${pkgs.podman}/bin/podman network exists komodo-net || \
      ${pkgs.podman}/bin/podman network create komodo-net
      '';
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
  
  ## PROGRAMS & SERVICES ##
  # Enable podman
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
}
