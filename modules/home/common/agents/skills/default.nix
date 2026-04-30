#
# Shared Agent Skills configuration.
# Skills are directory-based: each subdirectory contains a SKILL.md
# and optionally a references/ directory with additional docs.
#
# To add a new skill: create a new directory here with a SKILL.md file!
# The directory name becomes the skill name (e.g., fish/SKILL.md -> fish skill)
# It will be automatically discovered and installed to ~/.agents/skills/
#
{ lib, ... }:
let
  # Auto-discover all subdirectories (each is a skill)
  skillDirs = lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./.);
in
{
  # Generate home.file entries for each skill directory (recursive links)
  home.file = lib.mapAttrs' (name: _: {
    name = ".agents/skills/${name}";
    value = {
      source = ./. + "/${name}";
      recursive = true;
    };
  }) skillDirs;
}
