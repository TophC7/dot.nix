#
# Agent tooling module orchestrator.
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

  # Install agent tooling packages.
  home.packages =
    let
      system = host.system;
      fromInputs = with inputs.llm-agents.packages.${system}; [
        claude-code
        codex
        copilot-cli
        gemini-cli
      ];
      fromPkgs = with pkgs; [
        beads
        crush
        t3code
        t3code-desktop
        ripgrep
      ];
    in
    fromInputs ++ fromPkgs;
}
