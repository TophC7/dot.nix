{
  pkgs,
  lib,
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

  inherit (lib.infra.containers) mkNetworkOptions;
in
{
  # ── Container ──
  virtualisation.oci-containers.containers.${name} = {
    image = "rapiz1/rathole:v0.5.0";
    cmd = [
      "--client"
      "/etc/rathole/client.toml"
    ];
    volumes = [ "${configFile}:/etc/rathole/client.toml:ro" ];
    log-driver = "journald";
    extraOptions = mkNetworkOptions {
      networkName = name;
      networkAlias = name;
      extraNetworks = [ "pangolin" ];
    };
  };

  # ── Service Config ──
  systemd.services = {
    "docker-${name}" = {
      after = [ "docker-network-${name}.service" ];
      requires = [ "docker-network-${name}.service" ];
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
  }
  // lib.infra.containers.mkDockerNetwork { inherit pkgs name; };

  # Bind network lifecycle to container
  systemd.services."docker-network-${name}" = {
    partOf = [ "docker-${name}.service" ];
    wantedBy = [ "docker-${name}.service" ];
  };
}
