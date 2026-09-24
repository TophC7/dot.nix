{
  inputs,
  secrets,
  pkgs,
  host,
  ...
}:
{
  imports = [
    inputs.sworm.nixosModules.sworm-server
  ];

  services.sworm-server = {
    enable = true;
    user = host.user.name;
    openFirewall = true;
    listen = "0.0.0.0:7420";
    authTokenFile = "${pkgs.writeText "sworm-token" (secrets.service.sworm.token or "")}";
  };
}
