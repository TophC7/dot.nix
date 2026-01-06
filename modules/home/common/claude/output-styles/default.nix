#
# Claude Code output styles configuration.
# Output styles define how Claude formats responses.
#
# To add a new style: just drop a .md file in this directory!
# It will be automatically discovered and installed to ~/.claude/output-styles/
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
    name = ".claude/output-styles/${name}";
    value = { source = ./. + "/${name}"; };
  }) mdFiles;
}
