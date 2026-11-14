{
  inputs,
  host,
  lib,
  ...
}:
{
  home.packages = [
    inputs.llm-agents.packages.${host.system}.antigravity-cli
  ]
  ++ lib.optional (host.desktop != null) inputs.llm-agents.packages.${host.system}.antigravity-hub;
}
