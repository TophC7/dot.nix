# Agent tooling module orchestrator.
{ pkgs, lib, ... }:
{
  imports = lib.fs.scanPaths ./home;

  home.packages = [ pkgs.ripgrep ];
}
