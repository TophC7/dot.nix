{
  secrets,
  host,
  ...
}:
let
  name = "komodo";
  store = "/store/komodo";
  env = secrets.service.komodo // {
    COMPOSE_KOMODO_IMAGE_TAG = "2";
    H_ENABLED = "false";
    KOMODO_DATABASE_ADDRESS = "mongo:27017";
    KOMODO_DISABLE_CONFIRM_DIALOG = "true";
    KOMODO_DISABLE_NON_ADMIN_CREATE = "false";
    KOMODO_DISABLE_USER_REGISTRATION = "false";
    KOMODO_ENABLE_NEW_USERS = "false";
    KOMODO_FIRST_SERVER = "https://${host.ip}:8120";
    KOMODO_GOOGLE_OAUTH_ENABLED = "false";
    KOMODO_HOST = "https://komodo.ryot.foo";
    KOMODO_JWT_TTL = "1-day";
    KOMODO_LOCAL_AUTH = "true";
    KOMODO_MONITORING_INTERVAL = "15-sec";
    KOMODO_RESOURCE_POLL_INTERVAL = "5-min";
    KOMODO_TITLE = "Komodo";
    KOMODO_TRANSPARENT_MODE = "false";
  };
in
{
  services.komodo-periphery = {
    rootDirectory = store;
    inbound = {
      ssl.enable = true;
      allowedIps = [ "172.16.0.0/12" ]; # Docker bridge subnet (Core container → host)
    };
  };

  virtualisation.oci-stacks.${name} = {
    containers = {
      "${name}-core" = {
        image = "ghcr.io/moghtech/komodo-core:${env.COMPOSE_KOMODO_IMAGE_TAG}";
        environment = env;
        volumes = [
          "${store}/cache:/repo-cache:rw"
          "${store}/core-keys:/config/keys:rw"
        ];
        labels."komodo.skip" = "";
        dependsOn = [ "${name}-mongo" ];
        log-driver = "local";
        extraOptions = [
          "--init"
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

    };
    description = "Komodo deployment management stack";
  };
}
