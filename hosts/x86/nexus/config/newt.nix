{ config, ... }:
let
  cfg = config.secretsSpec.docker.newt-nexus;
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
  };
}
