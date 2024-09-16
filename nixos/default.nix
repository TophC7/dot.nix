{ modulesPath, config, pkgs, ... }:

let

  hostname = "cloud";
  admin = "toph";
  password = "[REDACTED]";
  timeZone = "America/New_York";
  defaultLocale = "en_US.UTF-8";

in {
  
  ## MODULES & IMPORTS ##

  imports =
    [ 
      # Include the default lxc/lxd configuration.
      "${modulesPath}/virtualisation/lxc-container.nix"
      # Import hardware configuration.
      ./hardware-configuration.nix
      
      # Module imports

      # ACME
      ./modules/acme
      # cron
      ./modules/cron
      # Logrotate
      ./modules/logrotate
      # Nextcloud
      ./modules/nextcloud
      # Nginx
      ./modules/nginx
      # Snapraid-runner
      ./modules/snapraid
      # SSH
      ./modules/ssh
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

  ## TIMEZONE & LOCALE ##
  time.timeZone = timeZone;
  i18n.defaultLocale = defaultLocale;

  ## USERS ##
  users = {
    mutableUsers = false;
    users = {
      "${admin}" = {
        isNormalUser = true;
        createHome = true;
        homeMode = "750";
        home = "/home/${admin}";
        password = password;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClZstYoT64zHnGfE7LMYNiQPN5/gmCt382lC+Ji8lrH PVE"
          ];
      };

      nextcloud.extraGroups = [ "users" "root" "wheel" ];
      nextcloud.homeMode = "750";
    };
  };

  # INFO: Enable passwordless sudo.
  security.sudo.extraRules= [
    {  users = [ admin ];
      commands = [
        { command = "ALL" ;
          options= [ "NOPASSWD" ];
        }
      ];
    }
  ];

  ## PACKAGES ##

  nixpkgs.overlays = [ (import ./overlays) ];
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

  ## PROGRAMS & SERVICES ##
  
  # Shells
  environment.shells = with pkgs; [ bash fish ];
  programs.fish.enable = true;

  ## NIXOS ##

  # LXC specific configuration
  # Supress systemd units that don't work because of LXC.
  # https://blog.xirion.net/posts/nixos-proxmox-lxc/#configurationnix-tweak
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # This value determines the NixOS release with which your system is to be
  system.stateVersion = "24.11";
  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
