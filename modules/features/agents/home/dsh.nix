# DeepSeek Harness with the Zebes llama route; profile settings remain editable.
# Provider keys and sign-ins live in ~/.dsh/.credentials.yaml (web Models page).
{
  hosts,
  lib,
  pkgs,
  ...
}:
let
  zebes = import ./_zebes-models.nix hosts;
  json = pkgs.formats.json { };

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

  # The web profile's own patch is the layer Settings writes, so seeding the route
  # there keeps it editable; a home patch would outrank and lock the Models page.
  # Reset only providers.zebes and remove the retired workflow insertion.
  # Cordis patch rows can share an insert list or carry unrelated config.
  activation = pkgs.writeShellScript "activate-dsh" ''
    set -euo pipefail
    yq=${lib.getExe pkgs.yq-go}
    patch="$HOME/.dsh/profiles/web/cordis.patch.yml"

    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$patch")"
    [[ -s "$patch" ]] || echo '[]' > "$patch"
    if ! "$yq" -e 'any_c(.id == "llm-pi-ai")' "$patch" >/dev/null 2>&1; then
      "$yq" -i '. += [{"id": "llm-pi-ai"}]' "$patch"
    fi
    "$yq" -i '(.[] | select(.id == "llm-pi-ai") | .config.providers.zebes) = load("${zebesRoute}")' "$patch"
    "$yq" -i '
      del(.[] |
        select((keys | length) == 1) |
        select((.insert // []) | any_c(.id == "toph-workflow")) |
        select(.insert | all_c(.id == "toph-workflow"))
      ) |
      del(.[] |
        select((.insert // []) | any_c(.id == "toph-workflow")) |
        .insert[] | select(.id == "toph-workflow")
      )
    ' "$patch"
  '';
in
{
  home.packages = [ pkgs.dsh ];

  home.activation.dsh = lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${activation}";
}
