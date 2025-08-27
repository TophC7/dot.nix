{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Install claude-code package
  home.packages = [ pkgs.claude-code ];

  # Claude Code configuration
  home.file.".claude/settings_source" = {
    text = builtins.toJSON {
      # Permissions configuration
      allow = {
        # Allow common bash commands
        bash = [
          "grep"
          "ls"
          "find"
          "mv"
          "mkdir"
          "rm"
          "cp"
          "cat"
          "head"
          "tail"
          "rg" # ripgrep
          "fd" # fd-find
          "tree"
          "which"
          "whereis"
        ];

        # Allow web fetching from specific domains
        webFetch = [
          "github.com"
          "gitlab.com"
          "docs.anthropic.com"
          "nixos.org"
          "search.nixos.org"
        ];
      };

      # Deny access to sensitive files
      deny = {
        read = [
          ".env"
          ".envrc.local"
          "secrets.nix"
          ".git-crypt"
          "*.key"
          "*.pem"
        ];
      };

      # Configure notification sounds
      hooks = {
        stop = {
          type = "sound";
          path = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
        };
        notification = {
          type = "sound";
          path = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga";
        };
      };
    };

    onChange = ''
      mkdir -p $HOME/.claude
      cp $HOME/.claude/settings_source $HOME/.claude/settings.json
      chmod 644 $HOME/.claude/settings.json
    '';
  };
}
