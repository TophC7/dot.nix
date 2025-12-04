{
  secrets,
  ...
}:
let
  name = "komodo";
  store = "/store/komodo";
  env = secrets.service.komodo;
in
{
  virtualisation.oci-stacks.${name} = {
    containers = {
      "${name}-core" = {
        image = "ghcr.io/moghtech/komodo-core:latest";
        environment = env;
        volumes = [ "${store}/cache:/repo-cache:rw" ];
        labels."komodo.skip" = "";
        dependsOn = [ "${name}-mongo" ];
        log-driver = "local";
        extraOptions = [
          "--network=${name}"
          "--network-alias=core"
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
          "${store}/repos:/etc/komodo/repos:rw"
          "${store}/ssl:/etc/komodo/ssl:rw"
          "${store}/stacks:${store}/stacks:rw"
        ];
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
