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
    # ../../common/acme
    ../../common/lxc
    ../../common/ssh
    # ../../common/vscode-server

    # Import hardware configuration.
    ./hardware.nix

    # Local Modules
    # ./modules/caddy
    ./modules/frp
    ./modules/forgejo
    ./modules/komodo
  ];

  ## NETWORKING ##
  networking.firewall = {
    allowedTCPPorts = [
      [REDACTED]
      [REDACTED]
      [REDACTED]
      222 # GitTea SSH
      [REDACTED]
      [REDACTED]
      3003 # GitTea
      [REDACTED]
      [REDACTED]
      8080 # File Browser
      [REDACTED]
      [REDACTED]
      [REDACTED]
      [REDACTED]
      [REDACTED]
    ];

    # Game Server Ports
    allowedTCPPortRanges = [
      {
        [REDACTED]
        [REDACTED]
      }
    ];

    allowedUDPPorts = [
      8089 # Grafana
    ];
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
