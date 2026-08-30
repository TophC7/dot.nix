{
  inputs,
  hosts,
  pkgs,
  ...
}:
{
  imports = [ inputs.omp-nix.homeManagerModules.default ];

  programs.omp.enable = true;

  # Local inference on Zebes (llama-server, router mode).
  #
  # llama-server serves unauthenticated, and `auth: none` is what waives OMP's
  # apiKey requirement for a custom provider — no placeholder key needed.
  #
  # The private-range baseUrl is load-bearing, not laziness: OMP keys its
  # local-backend compat off a loopback/RFC1918 host — reasoning replay for
  # KV-cache hits across turns, Qwen `preserve_thinking`, no first-event
  # watchdog, a 300s stream idle floor, append-only context. A DNS name would
  # resolve fine and silently lose all of it.
  home.file.".omp/agent/models.yml".source = (pkgs.formats.yaml { }).generate "omp-models.yml" {
    providers.zebes = {
      baseUrl = "http://${hosts.zebes.ip}:11434/v1";
      api = "openai-completions";
      auth = "none";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
        maxTokensField = "max_tokens";
      };
      models =
        let
          # These templates always think and expose no effort control, so the
          # models carry `reasoning` with no `thinking` block — OMP reads that
          # as "reasoning model, no effort tiers". Pi's `thinkingLevelMap.off`
          # has no counterpart in OMP's schema.
          common = {
            reasoning = true;
            contextWindow = 131072;
            maxTokens = 32768;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          };
          vision = common // {
            input = [
              "text"
              "image"
            ];
          };
        in
        [
          (
            vision
            // {
              id = "qwen3.5-9b-opus-reasoning";
              name = "Qwen3.5/Opus";
            }
          )
          (
            vision
            // {
              id = "qwen3.5-9b-sushi-coder-rl";
              name = "Qwen3.5/Sushi Coder";
            }
          )
          (
            vision
            // {
              id = "qwen3.5-27b-opus-reasoning-v2";
              name = "Qwen3.5/Opus 27B";
            }
          )
          (
            common
            // {
              id = "ornith-1.0-35b";
              name = "Ornith 1.0/35B";
              input = [ "text" ];
            }
          )
        ];
    };
  };
}
