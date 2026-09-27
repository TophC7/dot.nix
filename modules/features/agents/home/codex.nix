{
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  agentPackages = inputs.llm-agents.packages.${host.system};
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills);

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".codex/skills/${name}";
    value = {
      source = ./_catalog/skills + "/${name}";
    };
  }) skillDirs;

in
{
  home.packages = [ agentPackages.codex ] ++ lib.optional (host.desktop != null) agentPackages.chatgpt;

  home.file = {
    ".codex/AGENTS.md".source = ./AGENTS.md;
  }
  // skillLinks;
}
