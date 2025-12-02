{
  pkgs,
  lib,
  consts,
  ...
}:
let
  name = "adguard";
  targetName = "docker-compose-${name}-root";
  volumePath = "${consts.DATA_BASE_PATH}/${name}";

  inherit (lib.infra.containers) serviceDefaults mkNetworkOptions;
in
{
  # ── Container ──
  virtualisation.oci-containers.containers.${name} = {
    image = "adguard/adguardhome:latest";
    volumes = [
      "${volumePath}/confdir:/opt/adguardhome/conf:rw"
      "${volumePath}/workdir:/opt/adguardhome/work:rw"
      "/var/lib/acme:/opt/adguardhome/work/acme:ro"
    ];
    ports = [
      "5453:53/tcp" # Remapped to avoid dnsmasq conflict
      "5453:53/udp"
      "853:853/tcp" # DNS over TLS
      "3000:3000/tcp" # Web UI
    ];
    log-driver = "journald";
    extraOptions = mkNetworkOptions {
      networkName = name;
      networkAlias = name;
    };
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
    unitConfig.Description = "AdGuard Home DNS stack";
    wantedBy = [ "multi-user.target" ];
  };
}
