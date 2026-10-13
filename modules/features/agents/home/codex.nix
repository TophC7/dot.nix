{
  inputs,
  host,
  lib,
  ...
}:
{
  home.packages = [
    inputs.llm-agents.packages.${host.system}.codex
  ]
  ++ lib.optional (host.desktop != null) inputs.llm-agents.packages.${host.system}.chatgpt;
}
