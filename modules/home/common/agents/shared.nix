#
# Shared agent root files.
#
{ ... }:
{
  home.file.".agents/AGENTS.md" = {
    source = ./AGENTS.md;
  };
}
