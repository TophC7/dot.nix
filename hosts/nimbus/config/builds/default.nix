# Build Orchestrator Module
{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;
}
