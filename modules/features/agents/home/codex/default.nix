# Codex-native workflow skills and role files.
# Keep skills under ~/.codex: DSH also loads ~/.agents/skills.
{
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  catalog = import ../../catalog { inherit lib; };
  vars = {
    "{{harness}}" = "Codex";
    "{{args}}" = "the text that follows the skill invocation";
    "{{prRef}}" = "GitHub PR URL or number";
    "{{askOffer}}" = "ask Toph, offering";
    "{{askRepo}}" = "ask Toph once";
    "{{askBatch}}" = "Ask Toph in one message containing";
    "{{askDecisions}}" = "Then ask Toph only the decisions";
    "{{internalUris}}" = "";
    "{{note}}" = "in a scratch note file outside the repository";
    "{{planGate}}" =
      "Plan mode must be active. If Codex is not in plan mode, stop and ask the user to enter it with `/plan`, then invoke `$decomplect` again.";
    "{{planSubmit}}" = "Present the finished plan and stop for approval.";
    "{{parallelBatches}}" =
      "with `spawn_agent` calls in one turn (`agent_type: \"decomplect-scout\"`) collected with `wait_agent`";
    "{{commitStep}}" =
      "3. Commit the staged changes from a message file: write the message to a new temporary file outside the repository with your file-writing tool, run `git commit -F <that file>`, then delete the file.";
    "{{prCreate}}" =
      "Create the PR with `gh pr create --repo <owner>/<repo> --base <resolved base> --head <head> --title \"<title>\" --body-file <file>`, writing the body to a new temporary file outside the repository with your file-writing tool first and deleting it afterward. Always pass the base resolved above.";
    "{{fastSubagent}}" = "use the fastest available model for them";
  };
  render = label: body: catalog.render vars "codex ${label}" body;
  bullets = names: lib.concatMapStrings (name: "- `${name}`\n") names;
  dispatch =
    entry:
    if entry ? batch then
      "Launch exactly one parallel batch: call `spawn_agent` once per agent below in a single turn, with `agent_type` set to the agent name and the task prompt in `message`; omit `fork_context`, `model`, and `reasoning_effort`. Collect every result with `wait_agent` before continuing.\n\n"
      + lib.removeSuffix "\n" (bullets entry.batch)
    else if entry ? single then
      "Launch the `${entry.single.agent}` agent: `spawn_agent` with `agent_type` `\"${entry.single.agent}\"` and message \"${entry.single.task}\", then `wait_agent`."
    else
      "";
  # Codex's skill walker skips symlinked files, so each skill directory links
  # to a store directory holding a regular SKILL.md.
  skill = name: text: {
    name = ".codex/skills/${name}";
    value.source = pkgs.writeTextDir "SKILL.md" text;
  };
  workflow =
    name: entry:
    skill name (
      catalog.withFrontmatter
        {
          inherit name;
          inherit (entry) description;
        }
        (render name (builtins.replaceStrings [ "{{dispatch}}" ] [ (dispatch entry.dispatch) ] entry.body))
    );
  macro =
    id: entry:
    let
      body = render "macro ${id}" (entry.skill or entry.body);
      planBody =
        if lib.hasPrefix "/plan " body then
          "Plan mode is required. If Codex is not in plan mode, stop and ask Toph to enter it with `/plan`, then invoke this skill again.\n\n"
          + lib.removePrefix "/plan " body
        else
          body;
    in
    skill "macro-${id}" (
      catalog.withFrontmatter {
        name = "macro-${id}";
        description = entry.summary;
      } planBody
    );
  agent =
    name: entry:
    let
      body = catalog.render (
        vars
        // lib.optionalAttrs (entry.output != null) {
          "{{report}}" = catalog.schemaContract entry.output;
        }
      ) "codex agent ${name}" entry.body;
    in
    {
      name = ".codex/agents/${name}.toml";
      value.text =
        "name = ${builtins.toJSON name}\n"
        + "description = ${builtins.toJSON entry.description}\n"
        + "developer_instructions = ${builtins.toJSON body}\n"
        + lib.optionalString (!(builtins.elem "bash" entry.tools)) "sandbox_mode = \"read-only\"\n";
    };
  files = [
    {
      name = ".codex/AGENTS.md";
      # spawn_agent children inherit this file, so Ponytail needs no subagent hook.
      value.text = render "instructions" (
        lib.concatStringsSep "\n\n" [
          catalog.soul
          catalog.rules
          catalog.caveman
          catalog.ponytail
        ]
      );
    }
  ]
  ++ lib.mapAttrsToList workflow catalog.workflows
  ++ lib.mapAttrsToList macro catalog.macros
  ++ lib.mapAttrsToList agent catalog.agents;
in
{
  home.packages = [
    inputs.llm-agents.packages.${host.system}.codex
  ]
  ++ lib.optional (host.desktop != null) inputs.llm-agents.packages.${host.system}.chatgpt;

  home.file = builtins.listToAttrs files;
}
