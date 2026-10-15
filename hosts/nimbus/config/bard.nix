# Bard MCP server for Gemini Apps, published by Pangolin as bard.ryot.foo through the
# host-network newt (target localhost:3085, health check /.well-known/oauth-authorization-server).
#
# To link Gemini:
#   1. Run `bard-cli link` on nimbus to generate client credentials and a 10-minute link code.
#   2. In Gemini Settings -> Connected Apps -> Custom apps, add https://bard.ryot.foo/mcp with
#      the Client ID and Client secret under Additional settings.
#   3. On the approval page, enter the link code and approve.
{
  host,
  inputs,
  pkgs,
  ...
}:
let
  user = host.user.name;
  home = host.user.homeDirectory;
  port = "3085";
  domain = "bard.ryot.foo";
  bard = inputs.bard.packages.${pkgs.stdenv.hostPlatform.system}.bard;
in
{
  environment.systemPackages = [ bard ];

  systemd.services.bard = {
    description = "Bard MCP server for Gemini Apps";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/${user}"
      "/run/current-system/sw"
    ];
    environment = {
      HOST = "127.0.0.1";
      PORT = port;
      ORIGIN = "https://${domain}";
      BARD_WORKSPACE = home;
      BARD_STATE_DIR = "${home}/.local/state/bard";
    };
    serviceConfig = {
      ExecStart = "${bard}/bin/bard";
      User = user;
      WorkingDirectory = home;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
