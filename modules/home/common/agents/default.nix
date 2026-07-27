# Agent tooling module orchestrator.
{
  pkgs,
  lib,
  inputs,
  host,
  ...
}:
{
  imports = (lib.fs.scanPaths ./.) ++ [
    inputs.pi-nix.homeManagerModules.default
  ];

  # Enable the pi.nix module setup
  programs.pi.enable = true;

  # Install agent tooling packages.
  home.packages =
    let
      system = host.system;
      fromInputs = with inputs.llm-agents.packages.${system}; [
        claude-code
        claude-desktop
        codex
        antigravity-cli
      ];
      fromPkgs = with pkgs; [
        ripgrep
      ];
    in
    fromInputs ++ fromPkgs;
}
