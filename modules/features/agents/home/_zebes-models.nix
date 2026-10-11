# llama-server on Zebes (router mode; presets in hosts/zebes/config/llama-models.nix).
# Harness-neutral facts; each harness maps them into its own provider schema.
#
# All models take images and cap output at 32k. `efforts` lists the levels the
# Qwen3.8 template accepts via chat_template_kwargs.reasoning_effort (anything else
# raises; enable_thinking = false really turns thinking off). Models without
# `efforts` always think and expose no effort control.
hosts: {
  baseUrl = "http://${hosts.zebes.ip}:11434/v1";
  maxTokens = 32768;
  models = [
    {
      id = "qwen3.8-27b";
      name = "Qwen3.8/27B";
      contextWindow = 65536;
      efforts = [
        "low"
        "medium"
        "xhigh"
      ];
    }
    {
      id = "qwen3.8-27b-abliterated";
      name = "Qwen3.8/27B Abliterated";
      contextWindow = 65536;
      efforts = [
        "low"
        "medium"
        "xhigh"
      ];
    }
    {
      id = "qwen3.5-9b-opus-reasoning";
      name = "Qwen3.5/Opus";
      contextWindow = 131072;
    }
    {
      id = "qwen3.5-9b-sushi-coder-rl";
      name = "Qwen3.5/Sushi Coder";
      contextWindow = 131072;
    }
  ];
}
