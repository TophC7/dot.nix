{ config, ... }:
let
  cfg = config.secretsSpec.docker."newt-${config.hostSpec.hostName}";
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
  };
}
