# Shared desktop Home Manager modules.
{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;
}
