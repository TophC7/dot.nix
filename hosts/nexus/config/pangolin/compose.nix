{
  pkgs,
  lib,
  consts,
  secrets,
  ...
}:
let
  name = "pangolin";
  targetName = "docker-compose-${name}-root";
  volumePath = "${consts.DATA_BASE_PATH}/${name}";

  # Network configuration
  networkSubnet = "10.1.1.0/24";
  networkGateway = "10.1.1.1";

  inherit (lib.infra.containers) serviceDefaults;

  # Helper: standard service config for this stack
  mkServiceConfig = extra: {
    serviceConfig = serviceDefaults;
    after = [ "docker-network-${name}.service" ] ++ (extra.after or [ ]);
    requires = [ "docker-network-${name}.service" ] ++ (extra.requires or [ ]);
    partOf = [ "${targetName}.target" ];
    wantedBy = [ "${targetName}.target" ];
  };
in
{
  # ── Containers ──
  virtualisation.oci-containers.containers = {
    gerbil = {
      image = "fosrl/gerbil:latest";
      volumes = [ "${volumePath}/config:/var/config:rw" ];
      ports = [
        "80:80/tcp"
        "443:443/tcp"
        "222:222/tcp"
        "51820:51820/udp" # WireGuard OLM
        "21820:21820/udp" # Client tunnels
        "25565:25565/tcp" # Minecraft port proxy
      ];
      cmd = [
        "--reachableAt=http://gerbil:3003"
        "--generateAndSaveKeyTo=/var/config/key"
        "--remoteConfig=http://pangolin:3001/api/v1/gerbil/get-config"
        "--reportBandwidthTo=http://pangolin:3001/api/v1/gerbil/receive-bandwidth"
      ];
      dependsOn = [ "pangolin" ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=gerbil"
        "--network=${name}"
        "--ip=10.1.1.11"
      ];
    };

    pangolin = {
      image = "fosrl/pangolin:latest";
      volumes = [ "${volumePath}/config:/app/config:rw" ];
      log-driver = "journald";
      extraOptions = [
        ''--health-cmd=["curl", "-f", "http://localhost:3001/api/v1/"]''
        "--health-interval=3s"
        "--health-retries=15"
        "--health-timeout=3s"
        "--network-alias=pangolin"
        "--network=${name}"
        "--ip=10.1.1.10"
        "--mac-address=02:42:68:28:01:10"
      ];
    };

    traefik = {
      image = "traefik:v3.4.0";
      environment.CLOUDFLARE_DNS_API_TOKEN = secrets.service.cloudflare.token;
      volumes = [
        "${volumePath}/config/letsencrypt:/letsencrypt:rw"
        "${volumePath}/config/traefik:/etc/traefik:ro"
      ];
      cmd = [ "--configFile=/etc/traefik/traefik_config.yml" ];
      dependsOn = [ "gerbil" "pangolin" ];
      log-driver = "journald";
      extraOptions = [ "--network=container:gerbil" ];
    };
  };

  # ── Service Configs ──
  systemd.services = {
    "docker-gerbil" = mkServiceConfig { };
    "docker-pangolin" = mkServiceConfig {
      after = [ "pangolin-config-sync.service" ];
      requires = [ "pangolin-config-sync.service" ];
    };
    "docker-traefik" = {
      # Traefik uses container networking (shares gerbil's network)
      serviceConfig = serviceDefaults;
      partOf = [ "${targetName}.target" ];
      wantedBy = [ "${targetName}.target" ];
    };

    # Custom network with subnet (can't use mkDockerNetwork)
    "docker-network-${name}" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f ${name}";
      };
      script = ''
        docker network inspect ${name} || docker network create ${name} \
          --driver=bridge \
          --opt com.docker.network.bridge.name=br-${name} \
          --subnet=${networkSubnet} \
          --ip-range=${networkSubnet} \
          --gateway=${networkGateway}
      '';
      partOf = [ "${targetName}.target" ];
      wantedBy = [ "${targetName}.target" ];
    };
  };

  # ── Root Target ──
  systemd.targets.${targetName} = {
    unitConfig.Description = "Pangolin reverse proxy stack";
    wantedBy = [ "multi-user.target" ];
  };
}
