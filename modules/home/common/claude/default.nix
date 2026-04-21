#
# Claude Code configuration module orchestrator.
# Auto-discovers sibling modules via lib.fs.scanPaths.
#
{
  pkgs,
  lib,
  inputs,
  host,
  ...
}:
{
  imports = lib.fs.scanPaths ./.;

  # Install claude-code package
  home.packages =
    let
      system = host.system;
    in
    [
      inputs.llm-agents.packages.${system}.claude-code
      inputs.llm-agents.packages.${system}.codex
      inputs.llm-agents.packages.${system}.copilot-cli
      inputs.llm-agents.packages.${system}.gemini-cli
      pkgs.crush
      pkgs.t3code
      pkgs.t3code-desktop
    ];
}
