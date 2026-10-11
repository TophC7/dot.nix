#
# Antigravity CLI: instructions, workflow/macro skills, agents, and always-on modes.
#
# Skills replaced Antigravity workflows (the legacy format dies October 2026) and the
# CLI converts each skill into a `/<name>` slash command. Skills load from both
# ~/.gemini/config/skills and ~/.gemini/antigravity-cli/skills; agents only from
# ~/.gemini/config/agents, which is why both live under the shared config root here.
#
{
  inputs,
  host,
  lib,
  ...
}:
let
  catalog = import ../catalog { inherit lib; };
  # Catalog agent roles (OMP's model roles) to Antigravity model tiers.
  models = {
    advisor = "pro";
    task = "pro";
    bard = "flash";
    smol = "flash";
    commit = "flash";
  };

  toolNames = {
    read = [ "view_file" ];
    grep = [ "grep_search" ];
    glob = [
      "find_by_name"
      "list_dir"
    ];
    bash = [
      "run_command"
      "write_to_file"
    ];
    lsp = [ ];
    ast_grep = [ ];
    github = [ ];
  };

  vars = {
    "{{harness}}" = "Antigravity";
    "{{args}}" = "the text that follows the skill invocation";
    "{{prRef}}" = "GitHub PR URL or number";
    "{{askOffer}}" = "use `ask_question` to offer";
    "{{askRepo}}" = "use `ask_question` once";
    "{{askBatch}}" = "Use one `ask_question` call containing";
    "{{askDecisions}}" = "Then use `ask_question` for only the decisions";
    "{{internalUris}}" = "";
    "{{note}}" = "in a scratch note file outside the repository";
    "{{planGate}}" =
      "Plan mode must be active. If it is not, stop and ask the user to switch to plan mode with Shift+Tab, then invoke `/decomplect` again.";
    "{{planSubmit}}" = "Present the finished plan and stop for approval.";
    "{{parallelBatches}}" =
      "with one `invoke_subagent` call holding one spec per owner (`TypeName: \"decomplect-scout\"`)";
    "{{commitStep}}" =
      "3. Commit the staged changes from a message file: write the message to a new temporary file outside the repository with your file-writing tool, run `git commit -F <that file>`, then delete the file.";
    "{{prCreate}}" =
      "Create the PR with `gh pr create --repo <owner>/<repo> --base <resolved base> --head <head> --title \"<title>\" --body-file <file>`, writing the body to a new temporary file outside the repository with your file-writing tool first and deleting it afterward. Always pass the base resolved above.";
    "{{fastSubagent}}" = "use the fastest available model for them";
  };

  render =
    extra: label: body:
    catalog.render (vars // extra) label body;

  dispatch =
    spec:
    if spec ? batch then
      "Launch exactly one parallel batch: one `invoke_subagent` call whose `Subagents` array holds one spec per agent below, with `TypeName` set to the agent name and the task prompt in `Prompt`. Collect every result before continuing.\n\n"
      + lib.concatMapStrings (name: "- `${name}`\n") spec.batch
    else if spec ? single then
      "Launch the `${spec.single.agent}` agent: one `invoke_subagent` call whose `Subagents` array holds one spec, with `TypeName` \"${spec.single.agent}\" and `Prompt` \"${spec.single.task}\"."
    else
      "";

  workflow = name: entry: {
    name = ".gemini/config/skills/${name}/SKILL.md";
    value.text =
      catalog.withFrontmatter
        {
          inherit name;
          inherit (entry) description;
        }
        (
          render { } "workflow ${name}" (
            builtins.replaceStrings [ "{{dispatch}}" ] [ (dispatch entry.dispatch) ] entry.body
          )
        );
  };

  macro =
    id: entry:
    let
      name = "macro-${id}";
      body = render { } "macro ${id}" (entry.skill or entry.body);
      planGate = "Plan mode is required. If you are not in plan mode, stop and ask Toph to switch with Shift+Tab, then invoke this skill again.\n\n";
    in
    {
      name = ".gemini/config/skills/${name}/SKILL.md";
      value.text = catalog.withFrontmatter {
        inherit name;
        description = entry.summary;
      } (if lib.hasPrefix "/plan " body then planGate + lib.removePrefix "/plan " body else body);
    };

  # Unknown capability names must fail: unknown native tool names can hang agents.
  agent = name: entry: {
    name = ".gemini/config/agents/${name}.md";
    value.text =
      catalog.withFrontmatter
        {
          inherit name;
          inherit (entry) description;
          tools = catalog.mapTools "antigravity" toolNames entry.tools;
          subagent = true;
          mainAgent = false;
          model = models.${entry.role};
        }
        (
          render (lib.optionalAttrs (entry.output != null) {
            "{{report}}" = catalog.schemaContract entry.output;
          }) "agent ${name}" entry.body
        );
  };

  files = [
    {
      name = ".gemini/GEMINI.md";
      # Subagents load user rules too, so Ponytail needs no per-agent copy.
      value.text = render { } "instructions" (
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
  home.packages = [ inputs.llm-agents.packages.${host.system}.antigravity-cli ];

  home.file = builtins.listToAttrs files;
}
