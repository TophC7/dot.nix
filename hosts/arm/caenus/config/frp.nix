{ config, ... }:
let
  frp-token = config.secretsSpec.api.frp;
in
{
  services.frp = {
    enable = true;
    role = "server";
    settings = {
      bindPort = 4040;
      auth = {
        method = "token";
        token = frp-token;
      };
    };
  };
}
