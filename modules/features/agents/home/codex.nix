{
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  agentPackages = inputs.llm-agents.packages.${host.system};
in
{
  home.packages = [
    agentPackages.codex
  ]
  ++ lib.optional (host.desktop != null) agentPackages.chatgpt;

  home.file = {
    ".codex/AGENTS.md".source = ./AGENTS.md;
  }
  // import ./_skills.nix lib ".codex/skills";
}
