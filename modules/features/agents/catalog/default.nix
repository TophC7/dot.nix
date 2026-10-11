# Single source for personal workflow prompts. Each prompt is one Markdown file
# with `+++` TOML frontmatter; adapters under ../home render them per harness.
{ lib }:
let
  markdown = import ./lib/markdown.nix { inherit lib; };
  schemas = import ./lib/schemas.nix;

  # TOML has no null; adapters test `output`/`report` against null.
  agent =
    entry:
    entry
    // {
      output = if entry ? output then schemas.${entry.output.schema} entry.output else null;
      report = entry.report or null;
    };
in
import ./lib/render.nix { inherit lib; }
// {
  soul = builtins.readFile ./instructions/soul.md;
  rules = builtins.readFile ./instructions/rules.md;
  # Always-on: Caveman shapes replies to Toph; Ponytail also reaches subagents.
  caveman = builtins.readFile ./instructions/caveman.md;
  ponytail = builtins.readFile ./instructions/ponytail.md;

  agents = lib.mapAttrs (_: agent) (markdown.readDir ./agents);
  workflows = markdown.readDir ./workflows;
  macros = markdown.readDir ./macros;
}
