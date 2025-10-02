{ config, lib, ... }:
let
  cfg = config.secretsSpec.docker."olm-${config.hostSpec.hostName}";
  cfgWg = config.secretsSpec.network.${config.hostSpec.hostName}.wg or null;
  nexusPublicKey = config.secretsSpec.network.nexus.wg.publicKey;
in
{
  services.olm = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    autoStart = true;
    dns = "adguard.ryot.foo";
    logLevel = "DEBUG";

    vpnClient = lib.mkIf (cfgWg != null) {
      enable = true;
      privateKey = cfgWg.privateKey;
      address = cfgWg.address;
      serverPublicKey = nexusPublicKey;
      serverEndpoint = cfgWg.endpoint;
    };
  };
}
