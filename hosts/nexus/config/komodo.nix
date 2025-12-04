{
  consts,
  secrets,
  ...
}:
let
  name = "komodo";
  storagePath = "${consts.DATA_BASE_PATH}/${name}";
  env = secrets.service.komodo-nexus;
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

  # ── Container Stack ──
  virtualisation.oci-stacks.${name} = {
    containers = {
      "${name}-core" = {
        image = "ghcr.io/moghtech/komodo-core:latest";
        environment = env;
        volumes = [ "${storagePath}/cache:/repo-cache:rw" ];
        ports = [ "9120:9120/tcp" ];
        labels."komodo.skip" = "";
        dependsOn = [ "${name}-mongo" ];
        log-driver = "local";
        extraOptions = [
          "--network=${name}"
          "--network-alias=core"
          "--pull=always"
        ];
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
        extraOptions = [
          "--network=${name}"
          "--network-alias=mongo"
        ];
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
        extraOptions = [
          "--network=${name}"
          "--network-alias=periphery"
          "--pull=always"
        ];
      };
    };
    description = "Komodo deployment management stack";
  };
}
