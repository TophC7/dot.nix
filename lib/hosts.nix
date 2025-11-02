# Constants data implementation (host configuration)
# Non-sensitive configuration values for hosts
{
  pkgs,
  config,
  lib,
  ...
}:
let
  wgEndpoint = "pangolin.ryot.foo:51821";
in
{
  # No need to import spec here - it's imported in evalModules

  hostSpec = {
    ## ARM Hosts ##
    caenus = {
      network = {
        hostName = "caenus";
        ip = null; # Defined in secrets
        firewall = {
          allowedTCPPorts = [
            22
            80 # HTTP (Pangolin/Traefik)
            222 # Forgejo SSH port
            443 # HTTPS (Pangolin/Traefik)
            2333 # Rathole
            25565 # Minecraft
          ];
          allowedUDPPorts = [
            # 15637 # Enshrouded
            21820 # Client tunnels
            51820 # WireGuard OLM
            51821 # WireGuard VPN
          ];
        };
      };
      user = {
        name = "toph";
      };
      # mounts = {
      #   repo = true;
      # };
      isArm = true;
      isExternal = true;
      isServer = true;
      isMinimal = true;
    };

    wsl = {
      # TBD - Not working well yet on X Elite Laptop
      network = {
        hostName = "wsl";
        # wg = {
        #   privateKey = secrets.service."wg-wsl".privateKey;
        #   publicKey = secrets.service."wg-wsl".publicKey;
        #   address = "10.100.0.1/24"; # Client address
        #   endpoint = wgEndpoint;
        # };
        # vpn = true;
      };
      user = {
        name = "toph";
      };
      isArm = true;
      isMinimal = true;
      isExternal = true;
    };

    ## X86 Hosts ##
    gojo = {
      network = {
        hostName = "gojo";
        ip = "104.40.5.5"; # Update with actual IP if needed
      };
      user = {
        name = "gio";
      };
      gnome = true;
      isExternal = true;
    };

    haze = {
      network = {
        hostName = "haze";
        ip = "104.40.6.6"; # Update with actual IP if needed
      };
      user = {
        name = "cesar";
      };
      mounts = {
        repo = true;
        tank = true;
      };
      gnome = true;
    };

    lxc = {
      network = {
        hostName = "lxc";
        # Dynamic IP from Proxmox DHCP
      };
      user = {
        name = "toph";
      };
      isServer = true;
      isMinimal = true;
    };

    nexus = {
      network = {
        hostName = "nexus";
        ip = "104.40.1.1";
        firewall = {
          allowedTCPPorts = [
            53 # DNS
            80 # HTTP
            443 # HTTPS
            222 # Forgejo SSH
            853 # DNS over TLS
          ];
          allowedUDPPorts = [
            53 # DNS
            66 # DHCP
            67 # DHCP
          ];
        };
        wg = {
          publicKey = "PLACEHOLDER"; # Defined in secrets
          address = "10.100.0.1/24"; # Server address
          endpoint = null; # Server doesn't need endpoint
        };
      };
      user = {
        name = "toph";
      };
      mounts = {
        repo = true;
      };
      isServer = true;
      isMinimal = true;
    };

    nimbus = {
      network = {
        hostName = "nimbus";
        ip = "104.40.2.24";
        firewall = {
          allowedTCPPorts = [
            111 # rpcbind
            2049 # NFSv4
            10048 # mountd
          ];
          allowedUDPPorts = [
            111 # rpcbind
            2049 # NFSv4
            10048 # mountd
          ];
        };
      };
      user = {
        name = "toph";
      };
      mounts = {
        # hold = true;
        store = true;
      };
      isServer = true;
      isMinimal = true;
    };

    norion = {
      network = {
        hostName = "norion";
        ip = "104.40.2.7";
        vpn = true; # VPN client to nexus
        wg = {
          publicKey = "PLACEHOLDER"; # Defined in secrets
          address = "10.100.0.2/32"; # Client address
          endpoint = wgEndpoint;
        };
      };
      user = {
        name = "toph";
      };
      mounts = {
        fast = true;
        # hold = true;
        repo = true;
        store = true;
        tank = true;
      };
      gnome = true; # Laptop with desktop
      # niri = true;
    };

    rune = {
      network = {
        hostName = "rune";
        ip = "104.40.4.7";
      };
      user = {
        name = "toph";
      };
      mounts = {
        fast = true;
        # hold = true;
        repo = true;
        store = true;
        tank = true;
      };
      gnome = true; # Desktop system
      niri = true;
    };

    vm = {
      network = {
        hostName = "vm";
        # Dynamic IP from VM host
      };
      user = {
        name = "toph";
      };
      gnome = false; # Testing niri instead
      # niri = true; # Test niri configuration
    };

    zebes = {
      network = {
        hostName = "zebes";
        ip = "104.40.3.3";
        firewall = {
          allowedTCPPorts = [
            111 # rpcbind
            222 # Forgejo SSH
            2049 # NFSv4
            10048 # mountd
          ];
          # Game Server Ports
          allowedTCPPortRanges = [
            {
              from = 25565;
              to = 25570;
            }
          ];
          allowedUDPPorts = [
            111 # rpcbind
            2049 # NFSv4
            10048 # mountd
          ];
        };
      };
      mounts = {
        repo = true;
        tank = true;
      };
      user = {
        name = "toph";
      };
      isServer = true;
      isMinimal = true;
    };
  };
}
