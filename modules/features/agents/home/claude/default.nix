#
# Claude Code: catalog-native commands/agents, a workflow mod for macros, and
# Caveman as a main-conversation output style.
#
{
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  catalog = import ../../catalog { inherit lib; };
  # Catalog agent roles (OMP's model roles) to Claude Code model aliases.
  models = {
    advisor = "opus";
    task = "sonnet";
    bard = "sonnet";
    smol = "haiku";
    commit = "haiku";
  };

  toolNames = {
    read = [ "Read" ];
    grep = [ "Grep" ];
    glob = [ "Glob" ];
    bash = [
      "Bash"
      "Write"
    ];
    lsp = [ ];
    ast_grep = [ ];
    github = [ ];
  };

  vars = {
    "{{harness}}" = "Claude Code";
    "{{args}}" = "$ARGUMENTS";
    "{{prRef}}" = "GitHub PR URL or number";
    "{{askOffer}}" = "use `AskUserQuestion` to offer";
    "{{askRepo}}" = "use `AskUserQuestion` once";
    "{{askBatch}}" =
      "Use `AskUserQuestion`, in as few calls as its per-call question limit allows, containing";
    "{{askDecisions}}" = "Then use `AskUserQuestion` for only the decisions";
    "{{internalUris}}" = "";
    "{{note}}" = "in a scratch note file outside the repository";
    "{{planGate}}" =
      "Plan mode must be active. If it is not, call `EnterPlanMode` before anything else.";
    "{{planSubmit}}" = "Submit through `ExitPlanMode`.";
    "{{parallelBatches}}" =
      ''as parallel `Agent` calls in one message, `subagent_type: "decomplect-scout"`'';
    "{{commitStep}}" =
      "3. Commit the staged changes from a message file: write the message to a new temporary file outside the repository with your file-writing tool, run `git commit -F <that file>`, then delete the file.";
    "{{prCreate}}" =
      ''Create the PR with `gh pr create --repo <owner>/<repo> --base <resolved base> --head <head> --title "<title>" --body-file <file>`, writing the body to a new temporary file outside the repository with your file-writing tool first and deleting it afterward. Always pass the base resolved above.'';
    "{{fastSubagent}}" = "set each `Agent` call's `model` to `haiku`";
  };

  dispatch =
    spec:
    if spec ? batch then
      "Launch exactly one parallel batch: a single message containing one `Agent` call per agent below, each with `subagent_type` set to the agent name, a 3 to 5 word `description`, and a self-contained `prompt`. Omit `model` and `run_in_background`. If an agent below is not available as a subagent type, run its scope inline instead of skipping it.\n\n"
      + lib.concatMapStrings (name: "- `${name}`\n") spec.batch
    else if spec ? single then
      ''Launch the `${spec.single.agent}` agent: one `Agent` call with `subagent_type` `"${spec.single.agent}"` and the prompt "${spec.single.task}".''
    else
      "";

  command = name: workflow: {
    name = ".claude/commands/${workflow.claude}.md";
    value.text =
      catalog.withFrontmatter
        {
          inherit (workflow) description;
          argument-hint = "[target] [focus]";
        }
        (
          catalog.render vars "claude workflow ${name}" (
            builtins.replaceStrings [ "{{dispatch}}" ] [ (dispatch workflow.dispatch) ] workflow.body
          )
        );
  };

  agent = name: entry: {
    name = ".claude/agents/${name}.md";
    value.text =
      catalog.withFrontmatter
        {
          inherit name;
          inherit (entry) description;
          tools = lib.concatStringsSep ", " (catalog.mapTools "claude" toolNames entry.tools);
          model = models.${entry.role};
        }
        (
          catalog.render (
            vars
            // lib.optionalAttrs (entry.output != null) {
              "{{report}}" = catalog.schemaContract entry.output;
            }
          ) "claude agent ${name}" entry.body
        );
  };

  ponytail = catalog.render vars "claude ponytail" catalog.ponytail;

  # Plan (like Explore) skips CLAUDE.md, so it gets Ponytail from a hook; other
  # subagents inherit it from CLAUDE.md.
  planPonytail = pkgs.writeText "claude-plan-ponytail.json" (
    builtins.toJSON {
      hookSpecificOutput = {
        hookEventName = "SubagentStart";
        additionalContext = ponytail;
      };
    }
  );

  macroData = lib.mapAttrsToList (id: entry: {
    inherit id;
    inherit (entry) name summary;
    body = catalog.render vars "claude macro ${id}" entry.body;
  }) catalog.macros;

  # One store directory, linked as a whole: Claude rejects hook modules whose
  # real path leaves the plugin directory, which per-file home.file links do.
  workflowPlugin =
    pkgs.runCommand "claude-workflow-plugin"
      {
        passAsFile = [
          "manifest"
          "hooks"
          "register"
        ];
        manifest = builtins.toJSON {
          name = "workflow";
          version = "1.0.0";
          description = "Toph's workflow: editable macros";
        };
        hooks = builtins.toJSON {
          description = "Workflow macros";
          modules = [ "./register.ts" ];
        };
        register =
          "const DATA = " + builtins.toJSON { macros = macroData; } + ";\n" + builtins.readFile ./mod.ts;
      }
      ''
        install -Dm644 "$manifestPath" "$out/.claude-plugin/plugin.json"
        install -Dm644 "$hooksPath" "$out/hooks/hooks.json"
        install -Dm644 "$registerPath" "$out/hooks/register.ts"
      '';

  files = [
    {
      name = ".claude/CLAUDE.md";
      value.text =
        catalog.render vars "claude instructions" (catalog.soul + "\n\n" + catalog.rules)
        + "\n\n"
        + ponytail;
    }
    {
      # Output styles reach the main conversation, not ordinary subagents.
      name = ".claude/output-styles/caveman.md";
      value.text = catalog.withFrontmatter {
        name = "Caveman";
        description = "Terse replies; full technical substance";
        keep-coding-instructions = true;
      } catalog.caveman;
    }
    {
      name = ".claude/skills/workflow";
      value.source = workflowPlugin;
    }
  ]
  ++ lib.mapAttrsToList command catalog.workflows
  ++ lib.mapAttrsToList agent catalog.agents;
in
{
  home.packages = with inputs.llm-agents.packages.${host.system}; [
    claude-code
    claude-desktop
  ];

  home.file = builtins.listToAttrs files // {
    # Claude rewrites settings.json at runtime, so keep the declared defaults in a
    # source file it never touches and refresh the live copy on change.
    ".claude/settings_source" = {
      text = builtins.toJSON {
        model = "opus";
        alwaysThinkingEnabled = true;
        effortLevel = "high";
        outputStyle = "Caveman";
        attribution = {
          commit = "";
          pr = "";
          sessionUrl = false;
        };
        hooks.SubagentStart = [
          {
            matcher = "Plan";
            hooks = [
              {
                type = "command";
                command = "${pkgs.coreutils}/bin/cat ${planPonytail}";
              }
            ];
          }
        ];

        env = {
          CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT = true;
        };
      };

      onChange = ''
        coreutils="${pkgs.coreutils}/bin"

        "$coreutils/mkdir" -p "$HOME/.claude"
        "$coreutils/cp" "$HOME/.claude/settings_source" "$HOME/.claude/settings.json"
        "$coreutils/chmod" 644 "$HOME/.claude/settings.json"
      '';
    };
  };
}
