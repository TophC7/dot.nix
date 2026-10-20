# ntfy phone notifications and one-off agent requests on localhost:2586, published as
# ntfy.ryot.foo by Pangolin through the host-network newt (health check /v1/health).
# Pangolin SSO stays off; ntfy's own users, topic ACLs, and tokens gate access.
{ secrets, ... }:
let
  auth = secrets.service.ntfy;
in
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.ryot.foo";
      listen-http = "127.0.0.1:2586";
      behind-proxy = true;
      cache-duration = "72h";
      auth-default-access = "deny-all";
      auth-users = [
        "toph:${auth.TOPH_HASH}:admin"
        "axo:${auth.AXO_HASH}:user"
      ];
      auth-access = [
        "axo:agent-out:wo"
        "axo:requests:ro"
      ];
      auth-tokens = [ "axo:${auth.AXO_TOKEN}:axophyte" ];
    };
  };
}
