{
  modulesPath,
  config,
  pkgs,
  hostName,
  ...
}:
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
    allowedTCPPorts = [
      22
      443
      80
      81
      9120
      3001
      4041
      5001
      7475
      8070
      8080
      8090
      9120
    ];

    # Game Server Ports
    allowedTCPPortRanges = [
      {
        [REDACTED]
        [REDACTED]
      }
    ];

    allowedUDPPorts = [ ];
  };

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
    compose2nix
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
}
