{ config, ... }:
let
  cfg = config.secretsSpec.docker.newt-nimbus;
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
  };
}
