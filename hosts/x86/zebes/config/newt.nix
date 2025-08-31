{ config, ... }:
let
  cfg = config.secretsSpec.docker.newt-zebes;
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    useHostNetwork = true;
  };
}
