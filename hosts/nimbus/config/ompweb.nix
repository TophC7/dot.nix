# omp web UI, published by Pangolin as omp.ryot.foo through the host-network newt
# (target localhost:30177, health check /icon.svg, a public static asset).
{
  host,
  pkgs,
  secrets,
  ...
}:
let
  user = host.user.name;
  auth = secrets.service.ompweb;
in
{
  systemd.services.ompweb = {
    description = "omp web UI";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # The agent's shells run as Toph: give them his tools (and omp), not systemd's bare PATH.
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/${user}"
      "/run/current-system/sw"
    ];
    # Pangolin SSO is this deployment's login: Pangolin sends X-Omp-Web-Auth, and
    # ompweb holds only its digest. The trusted header works only with a password set,
    # so passwordHash is one nobody knows. Every omp session inherits this
    # environment, which is why neither value here is a usable credential.
    environment = {
      PORT = "30177";
      OMP_WEB_HOSTNAME = "127.0.0.1";
      OMP_WEB_NO_OPEN = "1";
      # Nix owns the package; in-app updates would try to rewrite the store.
      OMP_WEB_DISABLE_AUTOUPDATE = "1";
      OMP_WEB_PASSWORD_HASH = auth.passwordHash;
      OMP_WEB_TRUSTED_HEADER_SHA256 = builtins.hashString "sha256" auth.trustedHeader;
    };
    serviceConfig = {
      ExecStart = "${pkgs.ompweb}/bin/ompweb";
      User = user;
      WorkingDirectory = host.user.homeDirectory;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
