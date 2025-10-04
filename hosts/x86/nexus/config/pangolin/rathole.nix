{
  config,
  pkgs,
  lib,
  consts,
  ...
}:
let
  ratholeToken = config.secretsSpec.api.rathole;
  caenusIp = config.secretsSpec.network.caenus.ip;

  # Rathole client configuration
  ratholeConfig = pkgs.writeText "rathole-client.toml" ''
    [client]
    remote_addr = "${caenusIp}:2333"  # Rathole server control port

    # Default token for all services
    default_token = "${ratholeToken}"

    # Retry and heartbeat settings
    retry_interval = 1
    heartbeat_timeout = 40

    # TCP service configurations
    [client.services.pangolin-http]
    type = "tcp"
    local_addr = "104.40.1.11:80"  # Gerbil's IP in pangolin network

    [client.services.pangolin-https]
    type = "tcp"
    local_addr = "104.40.1.11:443"

    [client.services.pangolin-ssh]
    type = "tcp"
    local_addr = "104.40.1.11:222"

    [client.services.pangolin-minecraft]
    type = "tcp"
    local_addr = "104.40.1.11:25565"

    # UDP service configurations
    [client.services.pangolin-tunnels]
    type = "udp"
    local_addr = "104.40.1.11:21820"

    [client.services.pangolin-wireguard-olm]
    type = "udp"
    local_addr = "104.40.1.11:51820"

    [client.services.wireguard-vpn]
    type = "udp"
    local_addr = "104.40.1.1:51821"
  '';
in
{
  # Rathole client container - has its own network + optional pangolin network
  virtualisation.oci-containers.containers."rathole" = {
    image = "rapiz1/rathole:v0.5.0"; # Official Rathole Docker image

    # Rathole expects the config at /app/config.toml by default
    # But we can override with command args
    cmd = [
      "--client"
      "/etc/rathole/client.toml"
    ];

    volumes = [
      "${ratholeConfig}:/etc/rathole/client.toml:ro"
    ];

    # Primary network: rathole's own network for core functionality
    # Secondary network: pangolin (optional, for pangolin-specific services)
    extraOptions = [
      "--network=rathole"
      "--network=pangolin"
    ];

    log-driver = "journald";
  };

  systemd.services = {
    # Rathole client service - independent with its own network
    "docker-rathole" = {
      after = [ "docker-network-rathole.service" ];
      requires = [ "docker-network-rathole.service" ];

      # Optionally start after pangolin (for pangolin-specific tunnels)
      wants = [
        "docker-network-pangolin.service"
        "docker-gerbil.service"
      ];

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartSec = lib.mkOverride 90 "10s";
      };
    };

    # Rathole Docker network
    "docker-network-rathole" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f rathole";
      };
      script = ''
        docker network inspect rathole || docker network create --driver bridge rathole
      '';
      partOf = [ "docker-rathole.service" ]; # Stop when rathole container stops
      wantedBy = [ "docker-rathole.service" ];
    };
  };
}
