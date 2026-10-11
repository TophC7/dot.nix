# DeepSeek Harness: native workflows and editable macros, plus the Zebes llama route.
# Provider keys and sign-ins live in ~/.dsh/.credentials.yaml (web Models page).
{
  hosts,
  lib,
  pkgs,
  ...
}:
let
  catalog = import ../../catalog { inherit lib; };
  zebes = import ../_zebes-models.nix hosts;
  json = pkgs.formats.json { };

  vars = {
    "{{harness}}" = "DSH";
    "{{args}}" = "the text that follows the skill invocation";
    "{{prRef}}" = "GitHub PR URL or number";
    "{{askOffer}}" = "use `ask_user_question` to offer";
    "{{askRepo}}" = "use `ask_user_question` once";
    "{{askBatch}}" = "Use one `ask_user_question` call containing";
    "{{askDecisions}}" = "Then use `ask_user_question` for only the decisions";
    "{{internalUris}}" = "";
    "{{note}}" = "in a scratch note file outside the repository";
    "{{planGate}}" =
      "Plan mode must be active. If plan-mode instructions are absent, stop and ask the user to run `/plan`, then invoke `/decomplect` again.";
    "{{planSubmit}}" = "Submit through `exit_plan_mode`.";
    "{{parallelBatches}}" =
      "with concurrent `subagent` calls in one turn, each prompt starting with the decomplect-scout instructions under Agent instructions";
    "{{commitStep}}" =
      "3. Commit the staged changes from a message file: write the message to a new temporary file outside the repository with your file-writing tool, run `git commit -F <that file>`, then delete the file.";
    "{{prCreate}}" =
      ''Create the PR with `gh pr create --repo <owner>/<repo> --base <resolved base> --head <head> --title "<title>" --body-file <file>`, writing the body to a new temporary file outside the repository with your file-writing tool first and deleting it afterward. Always pass the base resolved above.'';
    "{{fastSubagent}}" = "use the fastest available model for them";
  };

  render = label: body: catalog.render vars label body;
  bullets = names: lib.concatMapStrings (name: "- `${name}`\n") names;
  dispatch =
    entry:
    if entry.dispatch ? batch then
      "Launch exactly one parallel batch: call the `subagent` tool once per agent below in the same turn, each with a 3 to 5 word `description` and a `prompt` that starts with that agent's section under Agent instructions, followed by the task.\n\n"
      + bullets entry.dispatch.batch
    else if entry.dispatch ? single then
      let
        single = entry.dispatch.single;
      in
      ''Launch the `${single.agent}` agent: one `subagent` call whose `prompt` starts with the `${single.agent}` section under Agent instructions, followed by "${single.task}".''
    else
      "";

  agentNames =
    entry:
    if entry.dispatch ? batch then
      entry.dispatch.batch
    else if entry.dispatch ? single then
      [ entry.dispatch.single.agent ]
    else
      [ entry.dispatch.fanout ];

  # ponytail: scouts retain all DSH tools; add extra subagent rows with toolFilter
  # if native read-only restrictions become necessary.
  agentBody =
    name:
    let
      agent = catalog.agents.${name};
    in
    catalog.render (
      vars
      // lib.optionalAttrs (agent.output != null) {
        "{{report}}" = catalog.schemaContract agent.output;
      }
    ) "dsh agent ${name}" agent.body;

  workflow = name: entry: {
    name = ".dsh/skills/${name}/SKILL.md";
    value.text =
      catalog.withFrontmatter
        {
          inherit name;
          inherit (entry) description;
        }
        (
          render "dsh workflow ${name}" (
            builtins.replaceStrings [ "{{dispatch}}" ] [ (dispatch entry) ] entry.body
          )
          + "\n## Agent instructions\n"
          + lib.concatMapStrings (agent: "\n### ${agent}\n\n${agentBody agent}\n") (agentNames entry)
        );
  };

  macros = lib.mapAttrsToList (id: macro: {
    inherit id;
    inherit (macro) name summary;
    body = render "dsh macro ${id}" macro.body;
  }) catalog.macros;

  # Copied as one directory: per-file `${./file}` copies carry a hash prefix.
  workflowInsert = json.generate "dsh-toph-workflow.json" {
    insert = [
      {
        id = "toph-workflow";
        name = "${./plugin}/lib/index.js";
        config = { inherit macros; };
      }
    ];
  };

  files = [
    {
      name = ".dsh/AGENTS.md";
      # Subagent sessions load this file too, so Ponytail needs no extra injection.
      value.text = render "dsh instructions" (
        lib.concatStringsSep "\n\n" [
          catalog.soul
          catalog.rules
          catalog.caveman
          catalog.ponytail
        ]
      );
    }
  ]
  ++ lib.mapAttrsToList workflow catalog.workflows;

  # pi-ai route for llama-server. Its OpenAI client insists on some credential, so
  # a dummy Authorization header stands in. Qwen3.8 efforts travel as template
  # kwargs (pi-ai's built-in qwen-chat-template only toggles enable_thinking).
  zebesRoute = json.generate "dsh-zebes-route.json" {
    displayName = "Zebes";
    api = "openai-completions";
    baseURL = zebes.baseUrl;
    headers.Authorization = "Bearer none";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
      maxTokensField = "max_tokens";
    };
    models = map (
      model:
      {
        inherit (model) id name contextWindow;
        inherit (zebes) maxTokens;
        input = [
          "text"
          "image"
        ];
      }
      // (
        if model ? efforts then
          {
            reasoningEfforts = {
              off = null;
            }
            // lib.genAttrs model.efforts lib.id;
            compat = {
              thinkingFormat = "chat-template";
              chatTemplateKwargs = {
                enable_thinking."$var" = "thinking.enabled";
                preserve_thinking = true;
                reasoning_effort = {
                  "$var" = "thinking.effort";
                  omitWhenOff = true;
                };
              };
            };
          }
        else
          {
            # Always thinks; one level marks it as a reasoning model for replay.
            reasoningEfforts.medium = "medium";
            compat.thinkingFormat = "qwen-chat-template";
          }
      )
    ) zebes.models;
  };

  # The web profile's own patch is the layer Settings writes, so seeding rows
  # there keeps them editable; home-patch rows outrank and ignore Settings edits.
  # Only providers.zebes and the toph-workflow insert row are reset in place;
  # other entries, providers, and Settings overrides survive.
  activation = pkgs.writeShellScript "activate-dsh" ''
    set -euo pipefail
    yq=${lib.getExe pkgs.yq-go}
    patch="$HOME/.dsh/profiles/web/cordis.patch.yml"
    workflow='(.insert // []) | any_c(.id == "toph-workflow")'

    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$patch")"
    [[ -s "$patch" ]] || echo '[]' > "$patch"
    if ! "$yq" -e 'any_c(.id == "llm-pi-ai")' "$patch" >/dev/null 2>&1; then
      "$yq" -i '. += [{"id": "llm-pi-ai"}]' "$patch"
    fi
    "$yq" -i '(.[] | select(.id == "llm-pi-ai") | .config.providers.zebes) = load("${zebesRoute}")' "$patch"
    if "$yq" -e "any_c($workflow)" "$patch" >/dev/null 2>&1; then
      "$yq" -i "(.[] | select($workflow)) = load(\"${workflowInsert}\")" "$patch"
    else
      "$yq" -i '. += [load("${workflowInsert}")]' "$patch"
    fi
  '';
in
{
  home.packages = [ pkgs.dsh ];

  home.file = builtins.listToAttrs files;

  home.activation.dsh = lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${activation}";
}
