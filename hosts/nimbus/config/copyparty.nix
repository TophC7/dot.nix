# copyparty phone/agent file drop-box on localhost:3923, published as party.ryot.foo
# by Pangolin through the host-network newt (health check /?h, the login/control panel).
# Pangolin SSO stays off; copyparty's password accounts gate the inbox and outbox.
{
  config,
  host,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  auth = secrets.service.copyparty;
  cfg = config.services.copyparty;
in
{
  imports = [ inputs.copyparty.nixosModules.default ];

  services.copyparty = {
    enable = true;
    package = pkgs.copyparty;
    settings = {
      i = "127.0.0.1";
      p = 3923;
      urlform = "save,get";
      # PartyUP text is a nameless form POST; .txt makes it a text file (raw msg= body).
      put-name = "put-{now.6f}-{cip}.txt";
      xff-hdr = "x-forwarded-for";
      xff-src = "127.0.0.1/32";
      # Use the last XFF hop; confirm the right rproxy depth from copyparty's log on first run.
      rproxy = -1;
    };
    accounts = {
      toph.passwordFile = "${pkgs.writeText "copyparty-toph-password" auth.TOPH}";
      axo.passwordFile = "${pkgs.writeText "copyparty-axo-password" auth.AXO}";
    };
    volumes = {
      "/inbox" = {
        path = "/fast/copyparty/inbox";
        access = {
          rwmd = "toph";
          r = "axo";
        };
        flags.e2d = true;
      };
      "/outbox" = {
        path = "/fast/copyparty/outbox";
        access = {
          rwmd = "toph";
          w = "axo";
        };
        flags.e2d = true;
      };
    };
  };

  # The module creates the volume dirs. Their parent must share /fast's owner (the host user):
  # systemd-tmpfiles refuses to descend through a directory owned by a different non-root user.
  systemd.tmpfiles.rules = [ "d /fast/copyparty 0750 ${host.user.name} ${cfg.group} -" ];
}
