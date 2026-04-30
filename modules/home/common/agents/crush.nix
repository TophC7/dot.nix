#
# Crush configuration.
#
{ config, ... }:
{
  home.file.".config/crush/CRUSH.md" = {
    source = ./AGENTS.md;
  };

  home.file.".config/crush/crush.json" = {
    text = builtins.toJSON {
      "$schema" = "https://charm.land/crush.json";
      options = {
        context_paths = [
          "${config.home.homeDirectory}/.config/crush/CRUSH.md"
        ];
        skills_paths = [
          "${config.home.homeDirectory}/.agents/skills"
        ];
        initialize_as = "AGENTS.md";
      };
    };
  };
}
