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

  ## ENVIORMENT & PACKAGES ##
  nixpkgs.overlays = [ (import ../../nix/overlays) ];
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
    HOSTNAME = hostName;
  };
}
