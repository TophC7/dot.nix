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
    inputs.codex-desktop-linux.homeManagerModules.default
    inputs.pi-nix.homeManagerModules.default
  ];

  # Enable the pi.nix module setup
  programs.pi.enable = true;

  programs.codexDesktopLinux =
    let
      isDesktopHost = !(host.isServer or false);
      codexCli = inputs.llm-agents.packages.${host.system}.codex;
    in
    if isDesktopHost then {
      enable = true;
      cliPackage = codexCli;
    } else { };

  # Install agent tooling packages.
  home.packages =
    let
      system = host.system;
      fromInputs = with inputs.llm-agents.packages.${system}; [
        claude-code
        codex
        copilot-cli
        gemini-cli
        antigravity-cli
      ];
      fromPkgs = with pkgs; [
        t3code
        t3code-desktop
        ripgrep
      ];
    in
    fromInputs ++ fromPkgs;
}
