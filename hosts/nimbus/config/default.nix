{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  # Newt Networks
  services.newt = {
    extraNetworks = [
      "filerun"
      "explorer"
    ];
  };
}
