{ config, ... }:
let
  cfg = config.secretsSpec.docker.newt-sock;
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
  };
}
