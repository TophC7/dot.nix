{
  consts,
  ...
}:
let
  name = "adguard";
  volumePath = "${consts.DATA_BASE_PATH}/${name}";
in
{
  virtualisation.oci-stacks.${name} = {
    containers.${name} = {
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
      extraOptions = [
        "--network=${name}"
        "--network-alias=${name}"
      ];
    };
    description = "AdGuard Home DNS stack";
  };
}
