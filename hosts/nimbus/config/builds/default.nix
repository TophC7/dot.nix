# Build Services Module
#
# Auto-imports all build service configurations in this directory.
# Each service uses the mkBuildService factory from lib.nix.
#
{ lib, ... }:
{
  imports = lib.fs.scanPaths ./.;
}
