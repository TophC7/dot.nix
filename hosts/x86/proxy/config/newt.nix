{ config, ... }:
let
  cfg = config.secretsSpec.docker.newt-proxy;
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    useHostNetwork = true;
  };
}
