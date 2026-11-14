{
  inputs,
  secrets,
  lib,
  host,
  ...
}:
let
  axome = secrets.service.sworm;
in
{
  imports = [
    inputs.axome.nixosModules.axome-server
  ];

  services.axome-server = {
    enable = true;
    user = host.user.name;
    openFirewall = true;
    listen = "0.0.0.0:7420";
    identityFile = "/etc/axome/server.pem";
    authorizedKeys = lib.mapAttrsToList (name: client: "${client.fingerprint} ${name}") axome.clients;
    web = {
      enable = true;
      openFirewall = true;
      listen = "0.0.0.0:7421";
    };
  };

  # Copied, not linked: axome, like ssh, refuses keys other users can read.
  environment.etc."axome/server.pem" = {
    text = axome.server.key;
    mode = "0600";
    user = host.user.name;
  };
}
