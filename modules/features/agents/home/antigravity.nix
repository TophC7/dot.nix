{
  inputs,
  host,
  lib,
  ...
}:
{
  home.packages = [ inputs.llm-agents.packages.${host.system}.antigravity-cli ];

  home.file = {
    ".gemini/GEMINI.md".source = ./AGENTS.md;
  }
  // import ./_skills.nix lib ".gemini/antigravity-cli/skills";
}
