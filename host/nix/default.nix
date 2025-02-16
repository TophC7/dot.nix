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
    ../../common/vscode-server

    # Import hardware configuration.
    ./hardware.nix
  ];

  ## NETWORKING ##
  networking.firewall = {
    allowedTCPPorts = [
      22
      80
      443
    ];
    allowedUDPPorts = [ ];
  };

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
    git
    micro
    openbox
    openssh
    ranger
    sshfs
    wget
    x2goserver
  ];

  programs.java = {
    enable = true;
    package = pkgs.jdk;
  };

  environment.variables = {
    HOSTNAME = hostName;
  };
}
