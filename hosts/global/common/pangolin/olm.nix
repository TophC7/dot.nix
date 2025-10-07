{
  config,
  host,
  secrets,
  ...
}:
let
  cfg = secrets.service."olm-${host.network.hostName}";
in
{
  services.olm = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    autoStart = true;
    logLevel = "DEBUG";
    holepunch = true;
  };
}
