{
  lib,
  pkgs,
  consts,
  secrets,
  ...
}:
let
  name = "komodo";
  targetName = "docker-compose-${name}-root";
  storagePath = "${consts.DATA_BASE_PATH}/${name}";
  env = secrets.service.komodo-nexus;

  inherit (lib.infra.containers) serviceDefaults mkNetworkOptions;

  # Helper: standard service config for this stack
  mkServiceConfig = {
    serviceConfig = serviceDefaults;
    after = [ "docker-network-${name}.service" ];
    requires = [ "docker-network-${name}.service" ];
    partOf = [ "${targetName}.target" ];
    wantedBy = [ "${targetName}.target" ];
  };
in
{
  # ── Storage Directories ──
  systemd.tmpfiles.rules = [
    "d ${storagePath} 0755 1000 1004 -"
    "d ${storagePath}/cache 0755 1000 1004 -"
    "d ${storagePath}/mongo 0755 1000 1004 -"
    "d ${storagePath}/mongo/config 0755 1000 1004 -"
    "d ${storagePath}/mongo/data 0755 1000 1004 -"
    "d ${storagePath}/repos 0755 1000 1004 -"
    "d ${storagePath}/ssl 0755 1000 1004 -"
    "d ${storagePath}/stacks 0755 1000 1004 -"
  ];

  # ── Containers ──
  virtualisation.oci-containers.containers = {
    "${name}-core" = {
      image = "ghcr.io/moghtech/komodo-core:latest";
      environment = env;
      volumes = [ "${storagePath}/cache:/repo-cache:rw" ];
      ports = [ "9120:9120/tcp" ];
      labels."komodo.skip" = "";
      dependsOn = [ "${name}-mongo" ];
      log-driver = "local";
      extraOptions =
        mkNetworkOptions {
          networkName = name;
          networkAlias = "core";
        }
        ++ [ "--pull=always" ];
    };

    "${name}-mongo" = {
      image = "mongo";
      environment = env;
      volumes = [
        "${storagePath}/mongo/config:/data/configdb:rw"
        "${storagePath}/mongo/data:/data/db:rw"
      ];
      cmd = [
        "--quiet"
        "--wiredTigerCacheSizeGB"
        "0.25"
      ];
      labels."komodo.skip" = "";
      log-driver = "local";
      extraOptions = mkNetworkOptions {
        networkName = name;
        networkAlias = "mongo";
      };
    };

    "${name}-periphery" = {
      image = "ghcr.io/moghtech/komodo-periphery:latest";
      environment = env;
      volumes = [
        "/proc:/proc:rw"
        "/var/run/docker.sock:/var/run/docker.sock:rw"
        "${storagePath}/repos:/etc/komodo/repos:rw"
        "${storagePath}/ssl:/etc/komodo/ssl:rw"
        "${storagePath}/stacks:${storagePath}/stacks:rw"
      ];
      ports = [ "8120:8120/tcp" ];
      labels."komodo.skip" = "";
      log-driver = "local";
      extraOptions =
        mkNetworkOptions {
          networkName = name;
          networkAlias = "periphery";
        }
        ++ [ "--pull=always" ];
    };
  };

  # ── Service Configs ──
  systemd.services = {
    "docker-${name}-core" = mkServiceConfig;
    "docker-${name}-mongo" = mkServiceConfig;
    "docker-${name}-periphery" = mkServiceConfig;
  }
  // lib.infra.containers.mkDockerNetwork { inherit pkgs name; };

  systemd.services."docker-network-${name}" = {
    partOf = [ "${targetName}.target" ];
    wantedBy = [ "${targetName}.target" ];
  };

  # ── Root Target ──
  systemd.targets.${targetName} = {
    unitConfig.Description = "Komodo deployment management stack";
    wantedBy = [ "multi-user.target" ];
  };
}
