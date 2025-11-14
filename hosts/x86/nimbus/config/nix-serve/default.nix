{
  pkgs,
  secrets,
  ...
}:
{
  services.nix-serve = {
    enable = true;
    port = 4488;
    secretKeyFile = "${pkgs.writeText "key.pem" secrets.service.cache.priv}";
    extraParams = "--workers 6";
  };
}
