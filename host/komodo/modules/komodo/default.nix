{config, pkgs, ... }:
{
  config.virtualisation.oci-containers.containers = {
    mongo = {
      image = "docker.io/mongo";
      cmd = [ "--quiet" ];
      autoStart = true;
      extraOptions = [ "--network=komodo-net" ];
      log-driver = "passthrough-tty";
      hostname = "mongo";
      ports = [ "27017:27017" ];
      volumes = [
        "/mnt/DockerStorage/komodo/mongo/data:/data/db"
        "/mnt/DockerStorage/komodo/mongo/config:/data/configdb"
      ];
      environmentFiles = [ ./komodo.env ];
      environment = {
        MONGO_INITDB_ROOT_USERNAME = "\${DB_USERNAME}";
        MONGO_INITDB_ROOT_PASSWORD = "\${DB_PASSWORD}";
      };
    };

    komodo = {
      image = "ghcr.io/mbecker20/komodo:latest";
      autoStart = true;
      extraOptions = [ "--network=komodo-net" ];
      dependsOn = [ "mongo" ];
      log-driver = "passthrough";
      hostname = "komodo";
      ports = [ "9120:9120" ];
      environmentFiles = [ ./komodo.env ];
      environment = {
        KOMODO_HOST = "\${KOMODO_HOST}";
        KOMODO_TITLE = "\${KOMODO_TITLE}";
        KOMODO_ENSURE_SERVER = "http://periphery:8120";
        KOMODO_MONGO_ADDRESS = "mongo:27017";
        KOMODO_MONGO_USERNAME = "\${DB_USERNAME}";
        KOMODO_MONGO_PASSWORD = "\${DB_PASSWORD}";
        KOMODO_PASSKEY = "\${KOMODO_PASSKEY}";
        KOMODO_WEBHOOK_SECRET = "\${KOMODO_WEBHOOK_SECRET}";
        KOMODO_JWT_SECRET = "\${KOMODO_JWT_SECRET}";
        KOMODO_LOCAL_AUTH = "\${KOMODO_LOCAL_AUTH}";
        KOMODO_DISABLE_USER_REGISTRATION = "\${KOMODO_DISABLE_USER_REGISTRATION}";
        KOMODO_GITHUB_OAUTH_ENABLED = "\${KOMODO_GITHUB_OAUTH_ENABLED}";
        KOMODO_GITHUB_OAUTH_ID = "\${KOMODO_GITHUB_OAUTH_ID}";
        KOMODO_GITHUB_OAUTH_SECRET = "\${KOMODO_GITHUB_OAUTH_SECRET}";
        KOMODO_GOOGLE_OAUTH_ENABLED = "\${KOMODO_GOOGLE_OAUTH_ENABLED}";
        KOMODO_GOOGLE_OAUTH_ID = "\${KOMODO_GOOGLE_OAUTH_ID}";
        KOMODO_GOOGLE_OAUTH_SECRET = "\${KOMODO_GOOGLE_OAUTH_SECRET}";
        KOMODO_AWS_ACCESS_KEY_ID = "\${KOMODO_AWS_ACCESS_KEY_ID}";
        KOMODO_AWS_SECRET_ACCESS_KEY = "\${KOMODO_AWS_SECRET_ACCESS_KEY}";
        KOMODO_HETZNER_TOKEN = "\${KOMODO_HETZNER_TOKEN}";
      };
    };

    periphery = {
      image = "ghcr.io/mbecker20/periphery:latest";
      autoStart = true;
      extraOptions = [ "--network=komodo-net" ];
      log-driver = "passthrough-tty";
      hostname = "periphery";
      volumes = [
        "/var/run/podman.sock:/var/run/docker.sock"
        "/mnt/DockerStorage/komodo/repos:/etc/komodo/repos"
        "mnt/DockerStorage/komodo/stacks:/etc/komodo/stacks"
      ];
      environment = {
        PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
      };
    };
  };
}