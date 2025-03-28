{ config, ... }:
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
      "/etc/cloudflared:/config"
    ];
  };
}
