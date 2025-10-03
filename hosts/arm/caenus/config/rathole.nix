{ config, ... }:
let
  # Generate a secret token for rathole authentication
  rathole-token = config.secretsSpec.api.rathole;
in
{
  services.rathole = {
    enable = true;
    role = "server";
    settings = {
      server = {
        bind_addr = "0.0.0.0:2333"; # Rathole control port

        # Default token for all services (can be overridden per service)
        default_token = rathole-token;

        # Heartbeat configuration (server only supports heartbeat_interval)
        heartbeat_interval = 10;
      };

      # Service definitions (TCP and UDP)
      server.services = {
        # TCP Services (migrated from FRP)
        "pangolin-http" = {
          bind_addr = "0.0.0.0:80";
          type = "tcp";
        };

        "pangolin-https" = {
          bind_addr = "0.0.0.0:443";
          type = "tcp";
        };

        "pangolin-ssh" = {
          bind_addr = "0.0.0.0:222";
          type = "tcp";
        };

        "pangolin-minecraft" = {
          bind_addr = "0.0.0.0:25565";
          type = "tcp";
        };

        # UDP Services
        "pangolin-tunnels" = {
          bind_addr = "0.0.0.0:21820";
          type = "udp";
        };

        "pangolin-wireguard-olm" = {
          bind_addr = "0.0.0.0:51820";
          type = "udp";
        };

        "pangolin-wireguard-vpn" = {
          bind_addr = "0.0.0.0:51821";
          type = "udp";
        };
      };
    };
  };

  # Open firewall ports for Rathole (these should already be open from network.firewall in secrets)
  networking.firewall = {
    allowedTCPPorts = [
      2333 # Rathole control port
      # TCP services are already allowed via secretsSpec.network.firewall
    ];
    allowedUDPPorts = [
      # UDP services are already allowed via secretsSpec.network.firewall
    ];
  };
}
