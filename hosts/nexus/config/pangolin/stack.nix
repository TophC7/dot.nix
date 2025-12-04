{
  consts,
  secrets,
  ...
}:
let
  name = "pangolin";
  volumePath = "${consts.DATA_BASE_PATH}/${name}";

  # Network configuration
  networkSubnet = "10.1.1.0/24";
  networkGateway = "10.1.1.1";
in
{
  # ── Container Stack ──
  virtualisation.oci-stacks.${name} = {
    containers = {
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

    # Custom network with subnet
    network = {
      name = name;
      script = ''
        docker network inspect ${name} || docker network create ${name} \
          --driver=bridge \
          --opt com.docker.network.bridge.name=br-${name} \
          --subnet=${networkSubnet} \
          --ip-range=${networkSubnet} \
          --gateway=${networkGateway}
      '';
    };

    description = "Pangolin reverse proxy stack";
  };

  # ── Extra Service Dependencies ──
  # pangolin container needs config sync service
  systemd.services."docker-pangolin" = {
    after = [ "pangolin-config-sync.service" ];
    requires = [ "pangolin-config-sync.service" ];
  };
}
