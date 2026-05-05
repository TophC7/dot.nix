#
# GitHub Copilot CLI custom instructions and skills.
#
{ lib, ... }:
let
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills);

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".copilot/skills/${name}";
    value = {
      source = ./_catalog/skills + "/${name}";
    };
  }) skillDirs;
in
{
  home.file =
    {
      ".copilot/copilot-instructions.md" = {
        source = ./AGENTS.md;
      };
    }
    // skillLinks;
}
