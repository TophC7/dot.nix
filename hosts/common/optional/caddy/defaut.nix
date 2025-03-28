{ config, ... }:
{
  imports = [
    "./${config.hostSpec.hostName}.nix"
  ];

  services.caddy = {
    enable = true;
  };
}
