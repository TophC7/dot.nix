{ config, ... }:
let
  cfg = config.secretsSpec.docker."olm-${config.hostSpec.hostName}";
in
{
  services.olm = {
    enable = true;
    id = cfg.ID;
    autoStart = true;
    dns = "adguard.ryot.foo";
    logLevel = "DEBUG";
    secret = cfg.SECRET;
  };
}
