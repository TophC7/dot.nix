{ config, ... }:
let
  cfg = config.secretsSpec.docker.newt-cloud;
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
  };
}
