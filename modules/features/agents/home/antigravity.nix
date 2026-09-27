{
  inputs,
  host,
  lib,
  ...
}:
let
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills);

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".gemini/antigravity-cli/skills/${name}";
    value.source = ./_catalog/skills + "/${name}";
  }) skillDirs;
in
{
  home.packages = [ inputs.llm-agents.packages.${host.system}.antigravity-cli ];

  home.file = {
    ".gemini/GEMINI.md".source = ./AGENTS.md;
  }
  // skillLinks;
}
