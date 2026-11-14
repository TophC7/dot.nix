# Agent tooling module orchestrator.
{
  pkgs,
  lib,
  secrets ? { },
  ...
}:
let
  models = secrets.service.models or { };
  apiKeys = lib.filterAttrs (k: v: lib.hasSuffix "_API_KEY" k && v != null && v != "") models;
in
{
  imports = lib.fs.scanPaths ./home;

  home.packages = with pkgs; [
    ripgrep
    orbit-pi
    orca-ide
    bb
  ];

  home.sessionVariables = apiKeys;
}
