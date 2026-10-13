# Claude Code settings use a source file to refresh the editable live settings.
{
  inputs,
  host,
  pkgs,
  ...
}:
{
  home.packages = with inputs.llm-agents.packages.${host.system}; [
    claude-code
    claude-desktop
  ];

  home.file.".claude/settings_source" = {
    # Claude rewrites settings.json at runtime, so keep the declared defaults in a
    # source file it never touches and refresh the live copy on change.
    text = builtins.toJSON {
      model = "opus";
      alwaysThinkingEnabled = true;
      effortLevel = "high";
      attribution = {
        commit = "";
        pr = "";
        sessionUrl = false;
      };
    };

    onChange = ''
      coreutils="${pkgs.coreutils}/bin"

      "$coreutils/mkdir" -p "$HOME/.claude"
      "$coreutils/cp" "$HOME/.claude/settings_source" "$HOME/.claude/settings.json"
      "$coreutils/chmod" 644 "$HOME/.claude/settings.json"
    '';
  };
}
