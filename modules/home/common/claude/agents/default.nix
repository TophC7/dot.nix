#
# Claude Code custom agents configuration.
# Agents are markdown files that define specialized autonomous agents.
#
# To add a new agent: just drop a .md file in this directory!
# The filename becomes the agent name (e.g., researcher.md -> researcher agent)
# It will be automatically discovered and installed to ~/.claude/agents/
#
{ lib, ... }:
let
  # Auto-discover all .md files in this directory
  mdFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".md" name
  ) (builtins.readDir ./.);
in
{
  # Generate home.file entries for each .md file
  home.file = lib.mapAttrs' (name: _: {
    name = ".claude/agents/${name}";
    value = { source = ./. + "/${name}"; };
  }) mdFiles;
}
