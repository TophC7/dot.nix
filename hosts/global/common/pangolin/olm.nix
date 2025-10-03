{ config, lib, ... }:
let
  cfg = config.secretsSpec.docker."olm-${config.hostSpec.hostName}";
  cfgWg = config.secretsSpec.network.${config.hostSpec.hostName}.wg or null;
  # caenusIp = config.secretsSpec.network.caenus.ip;
  nexusPublicKey = config.secretsSpec.network.nexus.wg.publicKey;
in
{
  services.olm = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    autoStart = true;
    # endpointIP = caenusIp;
    logLevel = "DEBUG";
    holepunch = true;

    # vpnClient = lib.mkIf (cfgWg != null) {
    #   enable = true;
    #   privateKey = cfgWg.privateKey;
    #   address = cfgWg.address;
    #   serverPublicKey = nexusPublicKey;
    #   serverEndpoint = cfgWg.endpoint;
    # };
  };
}
