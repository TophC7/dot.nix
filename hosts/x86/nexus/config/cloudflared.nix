{
  config,
  consts,
  ...
}:
let
  volumePath = "${consts.DATA_BASE_PATH}/cloudflared";
in
{
  config.virtualisation.oci-containers.containers.cloudflared = {
    image = "docker.io/wisdomsky/cloudflared-web:latest";
    autoStart = true;
    extraOptions = [
      "--network=host"
      "--pull=always"
    ];
    hostname = "cloudflared";
    volumes = [
      "${volumePath}:/config"
    ];
  };
}
