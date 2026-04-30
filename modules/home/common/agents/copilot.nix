#
# GitHub Copilot CLI custom instructions.
#
{ ... }:
{
  home.file.".copilot/copilot-instructions.md" = {
    source = ./AGENTS.md;
  };
}
