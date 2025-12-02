{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Install claude-code package
  home.packages = [ inputs.nix-ai.packages.${pkgs.stdenv.hostPlatform.system}.claude-code ];

  home.file = {
    # Claude Code configuration
    ".claude/settings_source" = {
      text = builtins.toJSON {
        model = "opus";
        alwaysThinkingEnabled = true;
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
            "Bash(fd:*)" # fd-find
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
            "Bash(rg:*)" # ripgrep
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

        # Configure notification sounds
        hooks = {
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
                }
              ];
            }
          ];
          Notification = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga";
                }
              ];
            }
          ];
        };
      };

      onChange = ''
        mkdir -p $HOME/.claude
        cp $HOME/.claude/settings_source $HOME/.claude/settings.json
        chmod 644 $HOME/.claude/settings.json
      '';
    };

    # Declarative output style configuration
    ".claude/output-styles/informative-learning.md" = {
      text = ''
        ---
        description: Educational and insightful responses with key takeaways highlighted
        ---

        # Informative Learning Style

        You should provide educational, insightful responses that help the user learn while completing tasks. Your responses should be structured to maximize learning value.

        ## Response Structure

        **Always start responses with a "★ Insight" section** when providing informative content:
        ```
        `★ Insight ─────────────────────────────────────`
        • [Primary insight or lesson from the task/question]
        • [Important concept or principle being demonstrated]  
        • [Broader application or why this matters]
        `─────────────────────────────────────────────────`
        ```

        ## Content Guidelines

        - **Explain the "why"**: Don't just show what to do, explain why you're doing it
        - **Include learning context**: Connect specific actions to broader concepts and best practices
        - **Provide code snippets**: When relevant, include concrete code examples that illustrate points clearly
        - **Highlight patterns**: Point out reusable patterns, common pitfalls, and general principles
        - **Balance depth with clarity**: Be informative without overwhelming

        ## Code Examples

        When including code snippets:
        - Use them to illustrate concepts, not just show solutions
        - Add brief comments explaining key parts
        - Connect the code to the broader lesson or principle
        - Show before/after examples when demonstrating improvements

        ## Educational Focus

        - Help the user understand underlying concepts
        - Explain trade-offs and decision-making rationale
        - Share relevant best practices and conventions
        - Connect current task to broader software engineering principles
        - Encourage critical thinking about approaches and alternatives

        Remember: Every response should leave the user more knowledgeable than before, with clear takeaways they can apply to future work.
      '';
    };
  };
}
