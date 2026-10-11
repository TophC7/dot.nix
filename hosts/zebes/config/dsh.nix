# DeepSeek Harness web UI, published by Pangolin as dsh.ryot.foo through the
# host-network newt (target localhost:3080, health check /manifest.webmanifest, the
# one unauthenticated 200). dsh only binds single addresses and its Host/Origin fence
# rejects unlisted authorities, hence loopback plus --trusted-host.
{
  host,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  user = host.user.name;
  port = "3080";
  domain = "dsh.ryot.foo";

  # Pangolin SSO is this deployment's login. Pangolin adds X-Dsh-Proxy-Secret to every
  # proxied request (resource → Proxy → Custom Headers) and dsh accepts it in place of
  # its per-process token cookie; local processes without the secret still face that
  # token. dsh also keeps Settings browser-only on non-loopback pages, so the public
  # hostname counts as local for persistence.
  dsh = pkgs.dsh.overrideAttrs (old: {
    postInstall = old.postInstall + ''
      lib=$out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-client-connection/lib
      substituteInPlace $lib/index.js --replace-fail 'isAuthenticated(request) {' '${''
        isAuthenticated(request) {
        		const proxySecret = process.env.DSH_PROXY_SECRET, presented = header(request.headers, "x-dsh-proxy-secret");
        		if (proxySecret && presented !== void 0 && tokenMatches(presented, proxySecret)) return true;''}'
      substituteInPlace $lib/client.js --replace-fail \
        'isLoopbackHostname(pageLocation.hostname),' \
        'isLoopbackHostname(pageLocation.hostname) || pageLocation.hostname === "${domain}",'
    '';
  });
in
{
  systemd.services.dsh = {
    description = "DeepSeek Harness web UI";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # The agent's shells run as Toph: give them his tools, not systemd's bare PATH.
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/${user}"
      "/run/current-system/sw"
    ];
    # API keys (launch environment outranks ~/.dsh/.credentials.yaml; read-only in the
    # UI) plus DSH_PROXY_SECRET.
    environment = secrets.service.dsh;
    serviceConfig = {
      ExecStart = "${lib.getExe dsh} web --no-open --port ${port} --trusted-host ${domain}";
      User = user;
      WorkingDirectory = host.user.homeDirectory;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
