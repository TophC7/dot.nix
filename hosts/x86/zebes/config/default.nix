{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;

  # Newt Networks
  services.newt = {
    extraNetworks = [
      "ai-network"
      "komodo"
      "explorer"
    ];
  };
}
