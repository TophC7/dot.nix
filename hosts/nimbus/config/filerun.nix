{
  pkgs,
  lib,
  secrets,
  ...
}:
let
  name = "filerun";
  targetName = "docker-compose-${name}-root";
  env = secrets.service.filerun;

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
    "${name}-db" = {
      image = "mariadb:10.11";
      environment = env;
      volumes = [ "/fast/filerun/db:/var/lib/mysql:rw" ];
      user = "1000:1004";
      log-driver = "journald";
      extraOptions = mkNetworkOptions {
        networkName = name;
        networkAlias = "db";
      };
    };

    "${name}-web" = {
      image = "filerun/filerun:8.1";
      environment = env;
      volumes = [
        "/tank/:/tank:rw"
        "/fast/filerun/html:/var/www/html:rw"
        "/tank/user-files:/user-files:rw"
      ];
      dependsOn = [ "${name}-db" ];
      user = "root";
      log-driver = "journald";
      extraOptions =
        mkNetworkOptions {
          networkName = name;
          networkAlias = "web";
        }
        ++ [ "--expose=80" ];
    };
  };

  # ── Service Configs ──
  systemd.services = {
    "docker-${name}-db" = mkServiceConfig;
    "docker-${name}-web" = mkServiceConfig;
  }
  // lib.infra.containers.mkDockerNetwork { inherit pkgs name; };

  systemd.services."docker-network-${name}" = {
    partOf = [ "${targetName}.target" ];
    wantedBy = [ "${targetName}.target" ];
  };

  # ── Root Target ──
  systemd.targets.${targetName} = {
    unitConfig.Description = "FileRun file management stack";
    wantedBy = [ "multi-user.target" ];
  };
}
