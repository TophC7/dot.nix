{ config, ... }:
let
  cfg = config.secretsSpec.docker."olm-${config.hostSpec.hostName}";
in
{
  services.olm = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    autoStart = true;
    logLevel = "DEBUG";
    holepunch = true;
  };
}
