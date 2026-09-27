{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;
}
