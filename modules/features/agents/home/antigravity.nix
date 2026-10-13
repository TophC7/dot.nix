{
  inputs,
  host,
  ...
}:
{
  home.packages = [ inputs.llm-agents.packages.${host.system}.antigravity-cli ];
}
