{
  inputs,
  hosts,
  ...
}:
{
  imports = [ inputs.pi-nix.homeManagerModules.default ];

  # Enable the pi.nix module setup
  programs.pi = {
    enable = true;
    antigravity.enable = true;
  };

  # Local inference on Zebes. llama-server ignores the placeholder API key,
  # but Pi requires configured auth before exposing a custom model.
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.zebes = {
      baseUrl = "http://${hosts.zebes.ip}:11434/v1";
      api = "openai-completions";
      apiKey = "local";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
        maxTokensField = "max_tokens";
      };
      models =
        let
          common = {
            reasoning = true;
            thinkingLevelMap.off = null;
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
