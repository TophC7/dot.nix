{
  pkgs,
  lib,
  secrets,
  ...
}:
let
  name = "komodo";
  targetName = "docker-compose-${name}-root";
  store = "/store/komodo";
  env = secrets.service.komodo;

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
  # ── Containers ──
  virtualisation.oci-containers.containers = {
    "${name}-core" = {
      image = "ghcr.io/moghtech/komodo-core:latest";
      environment = env;
      volumes = [ "${store}/cache:/repo-cache:rw" ];
      labels."komodo.skip" = "";
      dependsOn = [ "${name}-mongo" ];
      log-driver = "local";
      extraOptions =
        mkNetworkOptions {
          networkName = name;
          networkAlias = "core";
        }
        ++ [
          "--pull=always"
          "--expose=9120"
        ];
    };

    "${name}-mongo" = {
      image = "mongo";
      environment = env;
      volumes = [
        "${store}/mongo/config:/data/configdb:rw"
        "${store}/mongo/data:/data/db:rw"
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
        "${store}/repos:/etc/komodo/repos:rw"
        "${store}/ssl:/etc/komodo/ssl:rw"
        "${store}/stacks:${store}/stacks:rw"
      ];
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
  } // lib.infra.containers.mkDockerNetwork { inherit pkgs name; };

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
