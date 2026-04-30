#
# Gemini CLI global instructions and skills.
#
{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory;
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills);
in
{
  home.file =
    {
      ".gemini/GEMINI.md" = {
        source = ./AGENTS.md;
      };
    }
    // lib.mapAttrs' (name: _: {
      name = ".gemini/skills/${name}";
      value = {
        source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/.agents/skills/${name}";
      };
    }) skillDirs;
}
