{
  config,
  lib,
  pkgs,
  consts,
  ...
}:
let
  komodoStorage = "${consts.DATA_BASE_PATH}/komodo";
  env = config.secretsSpec.docker.komodo-nexus;
in
{
  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d ${komodoStorage} 0755 1000 1004 -"
    "d ${komodoStorage}/cache 0755 1000 1004 -"
    "d ${komodoStorage}/mongo 0755 1000 1004 -"
    "d ${komodoStorage}/mongo/config 0755 1000 1004 -"
    "d ${komodoStorage}/mongo/data 0755 1000 1004 -"
    "d ${komodoStorage}/repos 0755 1000 1004 -"
    "d ${komodoStorage}/ssl 0755 1000 1004 -"
    "d ${komodoStorage}/stacks 0755 1000 1004 -"
  ];

  # Containers
  virtualisation.oci-containers.containers."komodo-core" = {
    image = "ghcr.io/moghtech/komodo-core:latest";
    environment = env;
    volumes = [
      "${komodoStorage}/cache:/repo-cache:rw"
    ];
    ports = [
      "9120:9120/tcp"
    ];
    labels = {
      "komodo.skip" = "";
    };
    dependsOn = [
      "komodo-mongo"
    ];
    log-driver = "local";
    extraOptions = [
      "--network-alias=core"
      "--network=komodo"
      "--pull=always"
    ];
  };

  systemd.services."docker-komodo-core" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-komodo.service"
    ];
    requires = [
      "docker-network-komodo.service"
    ];
    partOf = [
      "docker-compose-komodo-root.target"
    ];
    wantedBy = [
      "docker-compose-komodo-root.target"
    ];
  };

  virtualisation.oci-containers.containers."komodo-mongo" = {
    image = "mongo";
    environment = env;
    volumes = [
      "${komodoStorage}/mongo/config:/data/configdb:rw"
      "${komodoStorage}/mongo/data:/data/db:rw"
    ];
    cmd = [
      "--quiet"
      "--wiredTigerCacheSizeGB"
      "0.25"
    ];
    labels = {
      "komodo.skip" = "";
    };
    log-driver = "local";
    extraOptions = [
      "--network-alias=mongo"
      "--network=komodo"
    ];
  };

  systemd.services."docker-komodo-mongo" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-komodo.service"
    ];
    requires = [
      "docker-network-komodo.service"
    ];
    partOf = [
      "docker-compose-komodo-root.target"
    ];
    wantedBy = [
      "docker-compose-komodo-root.target"
    ];
  };

  virtualisation.oci-containers.containers."komodo-periphery" = {
    image = "ghcr.io/moghtech/komodo-periphery:latest";
    environment = env;
    volumes = [
      "/proc:/proc:rw"
      "/var/run/docker.sock:/var/run/docker.sock:rw"
      "${komodoStorage}/repos:/etc/komodo/repos:rw"
      "${komodoStorage}/ssl:/etc/komodo/ssl:rw"
      "${komodoStorage}/stacks:${komodoStorage}/stacks:rw"
    ];
    ports = [
      "8120:8120/tcp"
    ];
    labels = {
      "komodo.skip" = "";
    };
    log-driver = "local";
    extraOptions = [
      "--network-alias=periphery"
      "--network=komodo"
      "--pull=always"
    ];
  };

  systemd.services."docker-komodo-periphery" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-komodo.service"
    ];
    requires = [
      "docker-network-komodo.service"
    ];
    partOf = [
      "docker-compose-komodo-root.target"
    ];
    wantedBy = [
      "docker-compose-komodo-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-komodo" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f komodo";
    };
    script = ''
      docker network inspect komodo || docker network create komodo
    '';
    partOf = [ "docker-compose-komodo-root.target" ];
    wantedBy = [ "docker-compose-komodo-root.target" ];
  };

  # Root service
  systemd.targets."docker-compose-komodo-root" = {
    unitConfig = {
      Description = "Komodo Docker Compose Services";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
