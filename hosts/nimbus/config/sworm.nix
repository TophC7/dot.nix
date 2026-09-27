{
  inputs,
  secrets,
  lib,
  host,
  ...
}:
let
  sworm = secrets.service.sworm;
in
{
  imports = [
    inputs.sworm.nixosModules.sworm-server
  ];

  services.sworm-server = {
    enable = true;
    user = host.user.name;
    openFirewall = true;
    listen = "0.0.0.0:7420";
    identityFile = "/etc/sworm/server.pem";
    authorizedKeys = lib.mapAttrsToList (name: client: "${client.fingerprint} ${name}") sworm.clients;
  };

  # Copied, not linked: sworm, like ssh, refuses keys other users can read.
  environment.etc."sworm/server.pem" = {
    text = sworm.server.key;
    mode = "0600";
    user = host.user.name;
  };
}
