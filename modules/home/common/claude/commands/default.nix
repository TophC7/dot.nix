#
# Claude Code custom commands (skills) configuration.
# Commands are markdown files that define custom slash commands.
#
# To add a new command: just drop a .md file in this directory!
# The filename becomes the command name (e.g., review.md -> /review)
# It will be automatically discovered and installed to ~/.claude/commands/
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
    name = ".claude/commands/${name}";
    value = { source = ./. + "/${name}"; };
  }) mdFiles;
}
