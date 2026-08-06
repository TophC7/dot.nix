# Agent tooling module orchestrator.
{ pkgs, lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  home.packages = [ pkgs.ripgrep ];
}
