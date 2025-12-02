{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  # Newt Networks
  services.newt = {
    extraNetworks = [
      "ai-network"
      "komodo"
      "explorer"
    ];
  };
}
