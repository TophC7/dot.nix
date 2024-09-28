{ config, ... }:
{
    config.virtualisation.oci-containers.containers.cloudflared = {
        image = "docker.io/wisdomsky/cloudflared-web:latest";
        autoStart = true;
        extraOptions = [
            "--network=host"
        ];
        hostname = "cloudflared";
        volumes = [
            "/etc/cloudflared:/config"
        ];
    };
}