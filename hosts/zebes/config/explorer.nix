{
  pkgs,
  lib,
  ...
}:
let
  name = "explorer";
  targetName = "docker-compose-${name}-root";

  inherit (lib.infra.containers) serviceDefaults mkNetworkOptions;
in
{
  # ── Container ──
  virtualisation.oci-containers.containers.${name} = {
    image = "nxzai/explorer:latest";
    environment = {
      GID = "1004";
      NODE_ENV = "production";
      UID = "1000";
    };
    volumes = [
      "/store/explorer:/cache:rw"
      "/store:/mnt/store:rw"
    ];
    log-driver = "journald";
    extraOptions =
      mkNetworkOptions {
        networkName = name;
        networkAlias = name;
      }
      ++ [ "--expose=3000" ];
  };

  # ── Service Config ──
  systemd.services."docker-${name}" = {
    serviceConfig = serviceDefaults;
    after = [ "docker-network-${name}.service" ];
    requires = [ "docker-network-${name}.service" ];
    partOf = [ "${targetName}.target" ];
    wantedBy = [ "${targetName}.target" ];
  };

  # ── Network ──
  systemd.services = lib.infra.containers.mkDockerNetwork { inherit pkgs name; };
  systemd.services."docker-network-${name}" = {
    partOf = [ "${targetName}.target" ];
    wantedBy = [ "${targetName}.target" ];
  };

  # ── Root Target ──
  systemd.targets.${targetName} = {
    unitConfig.Description = "Explorer file browser stack";
    wantedBy = [ "multi-user.target" ];
  };
}
