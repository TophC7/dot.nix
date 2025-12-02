{
  host,
  inputs,
  secrets,
  ...
}:
let
  cfg = secrets.service."newt-${host.hostName}";
in
{
  imports = [ inputs.mix-nix.nixosModules.newt ];

  services.newt = {
    enable = true;
    id = cfg.ID;
    secret = cfg.SECRET;
    pangolinEndpoint = "https://pangolin.ryot.foo";
    # extraNetworks = [ "traefik" "apps" ];
  };
}
