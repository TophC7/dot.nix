#
# Claude Code settings configuration.
# Uses staging pattern: settings_source -> onChange -> settings.json
#
{
  config,
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../_catalog/skills);
  agentFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
    builtins.readDir ../_catalog/agents
  );

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".claude/skills/${name}";
    value = {
      source = ../_catalog/skills + "/${name}";
    };
  }) skillDirs;

  agentLinks = lib.mapAttrs' (name: _: {
    name = ".claude/agents/${name}";
    value = {
      source = ../_catalog/agents + "/${name}";
    };
  }) agentFiles;
in
{
  home.packages = with inputs.llm-agents.packages.${host.system}; [
    claude-code
    claude-desktop
  ];

  home.file = {
    # Global CLAUDE.md - instructions that apply to every conversation
    ".claude/CLAUDE.md".source = ./CLAUDE.md;
    ".claude/output-styles/style.md".source = ./style.md;

    ".claude/settings_source" = {
      text = builtins.toJSON {
        model = "opus";
        alwaysThinkingEnabled = true;
        effortLevel = "high";
        outputStyle = "style";

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
  }
  // skillLinks
  // agentLinks;
}
