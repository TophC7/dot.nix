{ modulesPath, config, pkgs, ... }:
let

  hostname = "nix";

in {
  
  ## MODULES & IMPORTS ##
  imports = [
      # Common Modules
      ../../common/lxc
      ../../common/ssh

      # Import hardware configuration.
      ./hardware.nix
    ];
  
  ## NETWORKING ##
  networking = {
    firewall = {
      allowedTCPPorts = [ 80 443 ];
    };
    dhcpcd.enable = false;
    hostName = hostname;
    networkmanager.enable = true;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
    git
    micro
    nodejs_22
    openbox
    openssh
    pnpm
    prettierd
    ranger
    sshfs
    wget
    x2goserver
  ];
  
  programs.java = { 
    enable = true;
    package = pkgs.jdk; };

  environment.variables = {
    HOSTNAME = hostname;
  };

  ## VS CODE ##
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };
}
