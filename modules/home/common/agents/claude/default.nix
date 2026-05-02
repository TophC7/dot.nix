#
# Claude Code settings configuration.
# Uses staging pattern: settings_source -> onChange -> settings.json
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../skills);
  agentFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
    builtins.readDir ../agents
  );

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".claude/skills/${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/.agents/skills/${name}";
    };
  }) skillDirs;

  agentLinks = lib.mapAttrs' (name: _: {
    name = ".claude/agents/${name}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/.agents/agents/${name}";
    };
  }) agentFiles;
in
{
  imports = [
    ./output-styles
  ];

  home.file =
    {
      # Global CLAUDE.md - instructions that apply to every conversation
      ".claude/CLAUDE.md" = {
        source = ./CLAUDE.md;
      };

      ".claude/settings_source" = {
        text = builtins.toJSON {
          model = "opus";
          alwaysThinkingEnabled = true;
          effortLevel = "high";
          outputStyle = "ultra";

          env = {
            CLAUDE_CODE_SHELL = lib.getExe pkgs.fish;
          };

          # Beads (`bd`) auto-injects workflow context into Claude's session.
          # Declared here so it survives home-manager rebuilds.
          hooks = {
            SessionStart = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "bd prime";
                  }
                ];
              }
            ];
            PreCompact = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "bd prime";
                  }
                ];
              }
            ];
          };

          permissions = {
            allow = [
              # Allow common bash commands
              "Bash(awk:*)"
              "Bash(cat:*)"
              "Bash(cut:*)"
              "Bash(df:*)"
              "Bash(diff:*)"
              "Bash(du:*)"
              "Bash(eza:*)"
              "Bash(fd:*)"
              "Bash(file:*)"
              "Bash(find:*)"
              "Bash(free:*)"
              "Bash(grep:*)"
              "Bash(head:*)"
              "Bash(htop)"
              "Bash(ls:*)"
              "Bash(lscpu)"
              "Bash(mkdir:*)"
              "Bash(nslookup:*)"
              "Bash(ps:*)"
              "Bash(pwd)"
              "Bash(rg:*)"
              "Bash(sed:*)"
              "Bash(sort:*)"
              "Bash(ssh:*)"
              "Bash(stat:*)"
              "Bash(tail:*)"
              "Bash(top)"
              "Bash(tree:*)"
              "Bash(true)"
              "Bash(uname:*)"
              "Bash(uniq:*)"
              "Bash(wc:*)"
              "Bash(whereis:*)"
              "Bash(which:*)"
              "Bash(whoami)"
              "WebSearch"
              # Allow web fetching from specific domains
              "WebFetch(domain:docs.anthropic.com)"
              "WebFetch(domain:docs.digpangolin.com)"
              "WebFetch(domain:github.com)"
              "WebFetch(domain:gitlab.com)"
              "WebFetch(domain:nixos.org)"
              "WebFetch(domain:raw.githubusercontent.com)"
              "WebFetch(domain:search.nixos.org)"
              # Allow reading all files in /repo
              "Read(/repo/**)"
            ];
            deny = [
              # Deny access to sensitive files
              "Read(.env)"
              "Read(.envrc.local)"
              "Read(secrets.nix)"
              "Read(.git-crypt)"
              "Read(*.key)"
              "Read(*.pem)"
            ];
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
