{
  host,
  inputs,
  secrets,
  ...
}:
let
  cfg = secrets.service."olm-${host.hostName}";
in
{
  imports = [ inputs.mix-nix.nixosModules.olm ];

  services.olm = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    autoStart = false;
    logLevel = "DEBUG";
    holepunch = true;
    pangolinEndpoint = "https://pangolin.ryot.foo";
  };
}
