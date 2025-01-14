{
  modulesPath,
  config,
  pkgs,
  hostName,
  ...
}:
{
  ## MODULES & IMPORTS ##

  ## MODULES & IMPORTS ##
  imports = [
    # Common Modules
    ../../common/acme
    ../../common/ssh

    # Import hardware configuration.
    ./hardware.nix

    # Local Modules
    ./modules/frp
    ./modules/nginx
  ];

  ## BOOTLOADER ##

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## NETWORKING ##
  networking.firewall = {
    allowedTCPPorts = [
      22
      80
      443
      4040
      25565
    ];
    allowedUDPPorts = [ 4040 ];
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
