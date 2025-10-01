{ config, ... }:
let
  frp-token = config.secretsSpec.api.frp;
  caenus-ip = config.secretsSpec.network.caenus.ip;
in
{
  services.frp = {
    enable = true;
    role = "client";
    settings = {
      serverAddr = if caenus-ip != null then caenus-ip else "caenus";
      serverPort = 4040;
      auth = {
        method = "token";
        token = frp-token;
      };

      # Pangolin service proxies
      proxies = [
        {
          name = "pangolin-http";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 80;
          remotePort = 80;
        }
        {
          name = "pangolin-https";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 443;
          remotePort = 443;
        }
        {
          name = "pangolin-ssh";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 222;
          remotePort = 222;
        }
        {
          name = "pangolin-wireguard";
          type = "udp";
          localIP = "127.0.0.1";
          localPort = 51820;
          remotePort = 51820;
        }
        {
          name = "pangolin-tunnels";
          type = "udp";
          localIP = "127.0.0.1";
          localPort = 21820;
          remotePort = 21820;
        }
        {
          name = "pangolin-minecraft";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 25565;
          remotePort = 25565;
        }
      ];
    };
  };
}
