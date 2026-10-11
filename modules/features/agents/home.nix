# Agent tooling module orchestrator.
{
  pkgs,
  lib,
  secrets ? { },
  ...
}:
let
  models = secrets.service.models or { };
  apiKeys = lib.filterAttrs (k: _: lib.hasSuffix "_API_KEY" k) models;
in
{
  imports = lib.fs.scanPaths ./home;

  home.packages = [ pkgs.ripgrep ];

  home.sessionVariables = apiKeys;
}
