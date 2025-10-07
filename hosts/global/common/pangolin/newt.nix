{
  config,
  host,
  secrets,
  ...
}:
let
  cfg = secrets.service."newt-${host.network.hostName}";
in
{
  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
  };
}
