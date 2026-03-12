#
# Claude Code settings configuration.
# Uses staging pattern: settings_source -> onChange -> settings.json
#
{
  ...
}:
{
  # Global CLAUDE.md - instructions that apply to every conversation
  home.file.".claude/CLAUDE.md" = {
    source = ./CLAUDE.md;
  };

  home.file.".claude/settings_source" = {
    text = builtins.toJSON {
      model = "opus";
      alwaysThinkingEnabled = true;
      effortLevel = "high";
      outputStyle = "informative-learning";

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
      mkdir -p $HOME/.claude
      cp $HOME/.claude/settings_source $HOME/.claude/settings.json
      chmod 644 $HOME/.claude/settings.json
    '';
  };
}
