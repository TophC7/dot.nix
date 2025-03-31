# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

let
  # Only available in the Komodo LXC
  DockerStorage = "/mnt/DockerStorage/komodo/stacks/authentik";
in
{
  # Containers
  virtualisation.oci-containers.containers."authentik-postgresql" = {
    image = "docker.io/library/postgres:16-alpine";
    environmentFiles = [
      ./authentik.env
    ];
    volumes = [
      "${DockerStorage}/database:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=pg_isready -d \${POSTGRES_DB} -U \${POSTGRES_USER}"
      "--health-interval=30s"
      "--health-retries=5"
      "--health-start-period=20s"
      "--health-timeout=5s"
      "--network-alias=postgresql"
      "--network=authentik_default"
    ];
  };
  systemd.services."docker-authentik-postgresql" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-authentik_default.service"
    ];
    requires = [
      "docker-network-authentik_default.service"
    ];
    partOf = [
      "docker-compose-authentik-root.target"
    ];
    wantedBy = [
      "docker-compose-authentik-root.target"
    ];
  };
  virtualisation.oci-containers.containers."authentik-redis" = {
    image = "docker.io/library/redis:alpine";
    environmentFiles = [
      ./authentik.env
    ];
    volumes = [
      "${DockerStorage}/redis:/data:rw"
    ];
    cmd = [
      "--save"
      "60"
      "1"
      "--loglevel"
      "warning"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=redis-cli ping | grep PONG"
      "--health-interval=30s"
      "--health-retries=5"
      "--health-start-period=20s"
      "--health-timeout=3s"
      "--network-alias=redis"
      "--network=authentik_default"
    ];
  };
  systemd.services."docker-authentik-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-authentik_default.service"
    ];
    requires = [
      "docker-network-authentik_default.service"
    ];
    partOf = [
      "docker-compose-authentik-root.target"
    ];
    wantedBy = [
      "docker-compose-authentik-root.target"
    ];
  };
  virtualisation.oci-containers.containers."authentik-server" = {
    image = "ghcr.io/goauthentik/server:2024.12.2";
    environmentFiles = [
      ./authentik.env
    ];
    volumes = [
      "${DockerStorage}/custom-templates:/templates:rw"
      "${DockerStorage}/media:/media:rw"
    ];
    ports = [
      "9000:9000/tcp"
      "9443:9443/tcp"
    ];
    cmd = [ "server" ];
    dependsOn = [
      "authentik-postgresql"
      "authentik-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=server"
      "--network=authentik_default"
    ];
  };
  systemd.services."docker-authentik-server" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-authentik_default.service"
    ];
    requires = [
      "docker-network-authentik_default.service"
    ];
    partOf = [
      "docker-compose-authentik-root.target"
    ];
    wantedBy = [
      "docker-compose-authentik-root.target"
    ];
  };
  virtualisation.oci-containers.containers."authentik-worker" = {
    image = "ghcr.io/goauthentik/server:2024.12.2";
    environmentFiles = [
      ./authentik.env
    ];
    volumes = [
      "${DockerStorage}/certs:/certs:rw"
      "${DockerStorage}/media:/media:rw"
      "${DockerStorage}/templates:/templates:rw"
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    cmd = [ "worker" ];
    dependsOn = [
      "authentik-postgresql"
      "authentik-redis"
    ];
    user = "root";
    log-driver = "journald";
    extraOptions = [
      "--network-alias=worker"
      "--network=authentik_default"
    ];
  };
  systemd.services."docker-authentik-worker" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-authentik_default.service"
    ];
    requires = [
      "docker-network-authentik_default.service"
    ];
    partOf = [
      "docker-compose-authentik-root.target"
    ];
    wantedBy = [
      "docker-compose-authentik-root.target"
      "docker-compose-komodo-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-authentik_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f authentik_default";
    };
    script = ''
      docker network inspect authentik_default || docker network create authentik_default
    '';
    partOf = [ "docker-compose-authentik-root.target" ];
    wantedBy = [ "docker-compose-authentik-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-authentik-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [
      "multi-user.target"
    ];
  };
}
