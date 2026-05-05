#
# Gemini CLI global instructions and skills.
#
{ lib, ... }:
let
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills);

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".gemini/skills/${name}";
    value = {
      source = ./_catalog/skills + "/${name}";
    };
  }) skillDirs;
in
{
  home.file =
    {
      ".gemini/GEMINI.md" = {
        source = ./AGENTS.md;
      };
    }
    // skillLinks;
}
