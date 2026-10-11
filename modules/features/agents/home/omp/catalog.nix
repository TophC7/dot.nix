{ lib, catalog }:
let
  vars = {
    "{{harness}}" = "OMP";
    "{{args}}" = "$ARGUMENTS";
    "{{prRef}}" = "GitHub PR or `pr://` reference";
    "{{askOffer}}" = "use `ask` to offer";
    "{{askRepo}}" = "use `ask` once";
    "{{askBatch}}" = "Use one `ask` call containing";
    "{{askDecisions}}" = "Then `ask` only the decisions";
    "{{internalUris}}" = "internal URIs, ";
    "{{note}}" = "in a `local://` note";
    "{{planGate}}" =
      "Native plan mode must be active; the interactive `/decomplect` hook enters it. If plan-mode instructions are absent, stop and ask the user to run `/plan /decomplect` in the TUI.";
    "{{planSubmit}}" = "Submit through the native proposal flow.";
    "{{parallelBatches}}" = "in parallel `task` batches";
    "{{commitStep}}" =
      "3. Commit the staged changes using standard input:\n   Run:\n   ```bash\n   git commit -F - <<'EOF'\n   <commit message>\n   EOF\n   ```";
    "{{prCreate}}" =
      "Create the PR with the `github` tool using `op: \"pr_create\"` and explicit repository, base, head, title, and body. Do not invoke `gh pr create` through Bash.";
    "{{fastSubagent}}" = "use the `@smol` role (`model: \"@smol\"`)";
  };

  reports = {
    incremental = "For each finding, emit an incremental `yield` with `type: [\"findings\"]` and one schema-matching finding in `result.data`. After complete coverage, emit `type: [\"coverage_summary\"]` with a concise statement of evidence reviewed. If no findings exist, emit only the coverage summary, then stop.";
    terminal = "Return one terminal `yield` whose `data` matches the output schema.";
  };

  dispatch =
    workflow:
    if workflow.dispatch ? batch then
      let
        agents = workflow.dispatch.batch;
        count = toString (builtins.length agents);
        word =
          {
            "4" = "four";
            "6" = "six";
          }
          .${count} or (throw "omp: unsupported workflow batch size ${count}");
      in
      "Launch exactly one parallel `task` batch containing these ${word} dedicated agents:\n\n"
      + lib.concatStringsSep "\n" (map (name: "- `${name}`") agents)
    else if workflow.dispatch ? single then
      let
        inherit (workflow.dispatch.single) agent task;
        renderedTask = catalog.render vars "${workflow.name} task" task;
      in
      "Launch the `${agent}` agent:\n   Call `task(agent=\"${agent}\", task=\"${renderedTask}\")`."
    else
      "";

  workflowFiles = lib.mapAttrs' (
    id: workflow:
    lib.nameValuePair ".omp/agent/commands/${workflow.omp}.md" {
      text = catalog.withFrontmatter { inherit (workflow) description; } (
        catalog.render vars "workflow ${id}" (
          builtins.replaceStrings [ "{{dispatch}}" ] [ (dispatch workflow) ] workflow.body
        )
      );
    }
  ) catalog.workflows;

  agentFiles = lib.mapAttrs' (
    name: agent:
    lib.nameValuePair ".omp/agent/agents/${name}.md" {
      text =
        catalog.withFrontmatter
          (
            {
              inherit name;
              inherit (agent) description;
              tools = lib.concatStringsSep ", " agent.tools;
              model = "@${agent.role}";
              blocking = true;
              "read-summarize" = false;
            }
            // lib.optionalAttrs (agent.output != null) { inherit (agent) output; }
          )
          (
            catalog.render (
              vars
              // {
                "{{report}}" = if agent.report == null then "" else reports.${agent.report};
              }
            ) "agent ${name}" agent.body
          );
    }
  ) catalog.agents;

  macroFiles = lib.mapAttrs' (
    id: macro:
    lib.nameValuePair ".omp/agent/macros/${id}.md" {
      text = catalog.withFrontmatter { inherit (macro) name summary; } (
        catalog.render vars "macro ${id}" macro.body
      );
    }
  ) catalog.macros;

in
{
  ".omp/agent/AGENTS.md".text = catalog.render vars "soul" catalog.soul;
  # Task subagents get RULES.md but not AGENTS.md or APPEND_SYSTEM.md.
  ".omp/agent/RULES.md".text = catalog.render vars "rules" (
    catalog.rules + "\n\n" + catalog.ponytail
  );
  ".omp/agent/APPEND_SYSTEM.md".text = catalog.caveman;
}
// workflowFiles
// agentFiles
// macroFiles
