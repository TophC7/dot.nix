{
  lib,
  pkgs,
  secrets,
  ...
}:
let
  name = "rathole";

  # Gerbil's IP in pangolin network
  gerbilIp = "10.1.1.11";
  routerIp = "10.1.1.1";

  # Rathole client configuration
  configFile = pkgs.writeText "rathole-client.toml" ''
    [client]
    remote_addr = "${secrets.service.caenus.ip}:2333"
    default_token = "${secrets.service.rathole.token}"
    retry_interval = 1
    heartbeat_timeout = 40

    # TCP services
    [client.services.pangolin-http]
    type = "tcp"
    local_addr = "${gerbilIp}:80"

    [client.services.pangolin-https]
    type = "tcp"
    local_addr = "${gerbilIp}:443"

    [client.services.pangolin-ssh]
    type = "tcp"
    local_addr = "${gerbilIp}:222"

    [client.services.pangolin-minecraft]
    type = "tcp"
    local_addr = "${gerbilIp}:25565"

    # UDP services
    [client.services.pangolin-tunnels]
    type = "udp"
    local_addr = "${gerbilIp}:21820"

    [client.services.pangolin-wireguard-olm]
    type = "udp"
    local_addr = "${gerbilIp}:51820"

    [client.services.wireguard-vpn]
    type = "udp"
    local_addr = "${routerIp}:51821"
  '';
in
{
  # ── Container Stack ──
  virtualisation.oci-stacks.${name} = {
    containers.${name} = {
      image = "rapiz1/rathole:v0.5.0";
      cmd = [
        "--client"
        "/etc/rathole/client.toml"
      ];
      volumes = [ "${configFile}:/etc/rathole/client.toml:ro" ];
      log-driver = "journald";
      extraOptions = [
        "--network=${name}"
        "--network-alias=${name}"
        "--network=pangolin" # Also join pangolin network
      ];
    };

    network = {
      name = name;
      external = [ "pangolin" ]; # Soft dependency on pangolin network
    };

    description = "Rathole tunnel client";
  };

  # ── Extra Service Dependencies ──
  systemd.services."docker-${name}" = {
    # Also want gerbil to be running
    wants = [ "docker-gerbil.service" ];
    # Custom restart timing for tunnel reconnection
    serviceConfig = {
      RestartSec = lib.mkOverride 90 "10s";
    };
  };
}
