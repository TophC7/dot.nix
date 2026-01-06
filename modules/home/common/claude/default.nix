#
# Claude Code configuration module orchestrator.
# Auto-discovers sibling modules via lib.fs.scanPaths.
#
{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = lib.fs.scanPaths ./.;

  # Install claude-code package
  home.packages = [ inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.claude-code ];
}
