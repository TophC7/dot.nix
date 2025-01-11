# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."komodo-core" = {
    image = "ghcr.io/mbecker20/komodo:latest";
    environment = {
      "COMPOSE_KOMODO_IMAGE_TAG" = "latest";
      "DB_PASSWORD" = "[REDACTED]";
      "DB_USERNAME" = "admin";
      "KOMODO_DATABASE_ADDRESS" = "mongo:27017";
      "KOMODO_DATABASE_PASSWORD" = "[REDACTED]";
      "KOMODO_DATABASE_USERNAME" = "admin";
      "KOMODO_DISABLE_CONFIRM_DIALOG" = "false";
      "KOMODO_DISABLE_NON_ADMIN_CREATE" = "false";
      "KOMODO_DISABLE_USER_REGISTRATION" = "false";
      "KOMODO_ENABLE_NEW_USERS" = "false";
      "KOMODO_FIRST_SERVER" = "https://periphery:8120";
      "KOMODO_GITHUB_OAUTH_ENABLED" = "false";
      "KOMODO_GOOGLE_OAUTH_ENABLED" = "false";
      "KOMODO_JWT_SECRET" = "x5jVLA6ClfJKaOVymKtLUbFJbWnA2mGS5AbKL5FoJmB9fdZ30BzMAzXXcfLbFdxT";
      "KOMODO_JWT_TTL" = "1-day";
      "KOMODO_LOCAL_AUTH" = "true";
      "KOMODO_MONITORING_INTERVAL" = "15-sec";
      "KOMODO_OIDC_ENABLED" = "false";
      "KOMODO_PASSKEY" = "tvjs5utkaW0Xvpru7qjEKJF3w6RdkBUm98StyOGKJFy5kdpQ3ZRzJbSyJmpMYIhA";
      "KOMODO_RESOURCE_POLL_INTERVAL" = "5-min";
      "KOMODO_TITLE" = "Komodo";
      "KOMODO_TRANSPARENT_MODE" = "false";
      "KOMODO_WEBHOOK_SECRET" = "ZUjiO97F9z3gliI8nIfmxzhbtP1TZ9FJUGr870sGxIhtxXMshRwHfhELScXMnQxK";
      "PASSKEY" = "tvjs5utkaW0Xvpru7qjEKJF3w6RdkBUm98StyOGKJFy5kdpQ3ZRzJbSyJmpMYIhA";
      "PERIPHERY_INCLUDE_DISK_MOUNTS" = "/etc/hostname";
      "PERIPHERY_PASSKEYS" = "tvjs5utkaW0Xvpru7qjEKJF3w6RdkBUm98StyOGKJFy5kdpQ3ZRzJbSyJmpMYIhA";
      "PERIPHERY_SSL_ENABLED" = "true";
    };
    environmentFiles = [
      "/home/toph/git/dotfiles/host/komodo/modules/komodo/komodo.env"
    ];
    volumes = [
      "/mnt/DockerStorage/komodo/cache:/repo-cache:rw"
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
      "--network=komodo_default"
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
      "docker-network-komodo_default.service"
      # "docker-volume-komodo_repo-cache.service"
    ];
    requires = [
      "docker-network-komodo_default.service"
      # "docker-volume-komodo_repo-cache.service"
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
    environment = {
      "MONGO_INITDB_ROOT_PASSWORD" = "[REDACTED]";
      "MONGO_INITDB_ROOT_USERNAME" = "admin";
    };
    environmentFiles = [
      "/home/toph/git/dotfiles/host/komodo/modules/komodo/komodo.env"
    ];
    volumes = [
      "/mnt/DockerStorage/komodo/mongo/config:/data/configdb:rw"
      "/mnt/DockerStorage/komodo/mongo/data:/data/db:rw"
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
      "--network=komodo_default"
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
      "docker-network-komodo_default.service"
      # "docker-volume-komodo_mongo-config.service"
      # "docker-volume-komodo_mongo-data.service"
    ];
    requires = [
      "docker-network-komodo_default.service"
      # "docker-volume-komodo_mongo-config.service"
      # "docker-volume-komodo_mongo-data.service"
    ];
    partOf = [
      "docker-compose-komodo-root.target"
    ];
    wantedBy = [
      "docker-compose-komodo-root.target"
    ];
  };

  virtualisation.oci-containers.containers."komodo-periphery" = {
    image = "ghcr.io/mbecker20/periphery:latest";
    environment = {
      "COMPOSE_KOMODO_IMAGE_TAG" = "latest";
      "DB_PASSWORD" = "[REDACTED]";
      "DB_USERNAME" = "admin";
      "KOMODO_DISABLE_CONFIRM_DIALOG" = "false";
      "KOMODO_DISABLE_NON_ADMIN_CREATE" = "false";
      "KOMODO_DISABLE_USER_REGISTRATION" = "false";
      "KOMODO_ENABLE_NEW_USERS" = "false";
      "KOMODO_FIRST_SERVER" = "https://periphery:8120";
      "KOMODO_GITHUB_OAUTH_ENABLED" = "false";
      "KOMODO_GOOGLE_OAUTH_ENABLED" = "false";
      "KOMODO_JWT_SECRET" = "x5jVLA6ClfJKaOVymKtLUbFJbWnA2mGS5AbKL5FoJmB9fdZ30BzMAzXXcfLbFdxT";
      "KOMODO_JWT_TTL" = "1-day";
      "KOMODO_LOCAL_AUTH" = "true";
      "KOMODO_MONITORING_INTERVAL" = "15-sec";
      "KOMODO_OIDC_ENABLED" = "false";
      "KOMODO_PASSKEY" = "tvjs5utkaW0Xvpru7qjEKJF3w6RdkBUm98StyOGKJFy5kdpQ3ZRzJbSyJmpMYIhA";
      "KOMODO_RESOURCE_POLL_INTERVAL" = "5-min";
      "KOMODO_TITLE" = "Komodo";
      "KOMODO_TRANSPARENT_MODE" = "false";
      "KOMODO_WEBHOOK_SECRET" = "ZUjiO97F9z3gliI8nIfmxzhbtP1TZ9FJUGr870sGxIhtxXMshRwHfhELScXMnQxK";
      "PASSKEY" = "tvjs5utkaW0Xvpru7qjEKJF3w6RdkBUm98StyOGKJFy5kdpQ3ZRzJbSyJmpMYIhA";
      "PERIPHERY_INCLUDE_DISK_MOUNTS" = "/etc/hostname";
      "PERIPHERY_PASSKEYS" = "tvjs5utkaW0Xvpru7qjEKJF3w6RdkBUm98StyOGKJFy5kdpQ3ZRzJbSyJmpMYIhA";
      "PERIPHERY_SSL_ENABLED" = "true";
    };
    environmentFiles = [
      "/home/toph/git/dotfiles/host/komodo/modules/komodo/komodo.env"
    ];
    volumes = [
      "/proc:/proc:rw"
      "/var/run/docker.sock:/var/run/docker.sock:rw"
      "/mnt/DockerStorage/komodo/repos:/etc/komodo/repos:rw"
      "/mnt/DockerStorage/komodo/ssl:/etc/komodo/ssl:rw"
      "/mnt/DockerStorage/komodo/stacks:/etc/komodo/stacks:rw"
    ];
    labels = {
      "komodo.skip" = "";
    };
    log-driver = "local";
    extraOptions = [
      "--network-alias=periphery"
      "--network=komodo_default"
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
      "docker-network-komodo_default.service"
      # "docker-volume-komodo_repos.service"
      # "docker-volume-komodo_ssl-certs.service"
      # "docker-volume-komodo_stacks.service"
    ];
    requires = [
      "docker-network-komodo_default.service"
      # "docker-volume-komodo_repos.service"
      # "docker-volume-komodo_ssl-certs.service"
      # "docker-volume-komodo_stacks.service"
    ];
    partOf = [
      "docker-compose-komodo-root.target"
    ];
    wantedBy = [
      "docker-compose-komodo-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-komodo_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f komodo_default";
    };
    script = ''
      docker network inspect komodo_default || docker network create komodo_default
    '';
    partOf = [ "docker-compose-komodo-root.target" ];
    wantedBy = [ "docker-compose-komodo-root.target" ];
  };

  # # Volumes
  # systemd.services."docker-volume-komodo_mongo-config" = {
  #   path = [ pkgs.docker ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     docker volume inspect komodo_mongo-config || docker volume create komodo_mongo-config
  #   '';
  #   partOf = [ "docker-compose-komodo-root.target" ];
  #   wantedBy = [ "docker-compose-komodo-root.target" ];
  # };
  # systemd.services."docker-volume-komodo_mongo-data" = {
  #   path = [ pkgs.docker ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     docker volume inspect komodo_mongo-data || docker volume create komodo_mongo-data
  #   '';
  #   partOf = [ "docker-compose-komodo-root.target" ];
  #   wantedBy = [ "docker-compose-komodo-root.target" ];
  # };
  # systemd.services."docker-volume-komodo_repo-cache" = {
  #   path = [ pkgs.docker ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     docker volume inspect komodo_repo-cache || docker volume create komodo_repo-cache
  #   '';
  #   partOf = [ "docker-compose-komodo-root.target" ];
  #   wantedBy = [ "docker-compose-komodo-root.target" ];
  # };
  # systemd.services."docker-volume-komodo_repos" = {
  #   path = [ pkgs.docker ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     docker volume inspect komodo_repos || docker volume create komodo_repos
  #   '';
  #   partOf = [ "docker-compose-komodo-root.target" ];
  #   wantedBy = [ "docker-compose-komodo-root.target" ];
  # };
  # systemd.services."docker-volume-komodo_ssl-certs" = {
  #   path = [ pkgs.docker ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     docker volume inspect komodo_ssl-certs || docker volume create komodo_ssl-certs
  #   '';
  #   partOf = [ "docker-compose-komodo-root.target" ];
  #   wantedBy = [ "docker-compose-komodo-root.target" ];
  # };
  # systemd.services."docker-volume-komodo_stacks" = {
  #   path = [ pkgs.docker ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     docker volume inspect komodo_stacks || docker volume create komodo_stacks
  #   '';
  #   partOf = [ "docker-compose-komodo-root.target" ];
  #   wantedBy = [ "docker-compose-komodo-root.target" ];
  # };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-komodo-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
