{
  modulesPath,
  config,
  pkgs,
  hostName,
  admin,
  ...
}:
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

    # cron
    ./modules/cron
    # Filerun
    ./modules/filerun
    # Logrotate
    ./modules/logrotate
    # Caddy
    ./modules/caddy
    # Snapraid-runner
    ./modules/snapraid
  ];

  ## NETWORKING ##
  networking.firewall = {
    allowedTCPPorts = [
      22
      80
      443
      8181
    ];
    allowedUDPPorts = [ ];
  };

  ## USERS ##
  users.users.${admin}.extraGroups = [ "docker" ];

  ## ENVIORMENT & PACKAGES ##
  nixpkgs.overlays = [ (import ../../nix/overlays) ];
  environment.systemPackages = with pkgs; [
    arion
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
    HOSTNAME = hostName;
  };
}
