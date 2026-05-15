#
# Codex configuration.
# Keeps mutable Codex state in ~/.codex/config.toml while inserting a small
# Nix-managed block for shared agent behavior.
#
{
  lib,
  pkgs,
  ...
}:
let
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills);

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".codex/skills/${name}";
    value = {
      source = ./_catalog/skills + "/${name}";
    };
  }) skillDirs;

  codexFishGate = pkgs.writeTextFile {
    name = "codex-require-fish-wrapper";
    executable = true;
    text = ''
      #!${pkgs.fish}/bin/fish

      set -l cat ${pkgs.coreutils}/bin/cat
      set -l jq ${pkgs.jq}/bin/jq
      set -l payload ($cat | string collect)
      set -l tool_name (printf '%s' "$payload" | $jq -r '.tool_name // ""' | string collect)

      if test "$tool_name" != Bash
          exit 0
      end

      set -l command (printf '%s' "$payload" | $jq -r '.tool_input.command // ""' | string collect)
      set -l trimmed (string trim -- "$command")

      if string match -rq -- '^(command[[:space:]]+)?([^[:space:]]*/)?fish[[:space:]]+(-lc|-l[[:space:]]+-c|--login[[:space:]]+-c|--login[[:space:]]+--command)[[:space:]]+' "$trimmed"
          exit 0
      end

      set -l reason "Codex shell commands must run through Fish. Use: fish -lc '<command>'. Do not pass Fish syntax directly to the shell tool."
      $jq -cn --arg reason "$reason" '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: $reason
        }
      }'
    '';
  };
in
{
  home.file = {
    ".codex/AGENTS.md" = {
      source = ./AGENTS.md;
    };

    ".codex/config_source.toml" = {
      text = ''
        # Agent instruction discovery
        project_doc_fallback_filenames = [
          "CLAUDE.md",
          "GEMINI.md",
          ".github/copilot-instructions.md",
        ]
        project_doc_max_bytes = 65536

        # Codex hook guardrails
        features.codex_hooks = true

        [[hooks.PreToolUse]]
        matcher = "^Bash$"

        [[hooks.PreToolUse.hooks]]
        type = "command"
        command = "${codexFishGate}"
        timeout = 5
        statusMessage = "Requiring Fish shell wrapper"
      '';

      onChange = ''
        set -eu

        awk="${pkgs.gawk}/bin/awk"
        coreutils="${pkgs.coreutils}/bin"

        "$coreutils/mkdir" -p "$HOME/.codex"

        config="$HOME/.codex/config.toml"
        source="$HOME/.codex/config_source.toml"
        start="# BEGIN NIX MANAGED CODEX AGENT SETTINGS"
        end="# END NIX MANAGED CODEX AGENT SETTINGS"
        stripped="$("$coreutils/mktemp")"
        next="$("$coreutils/mktemp")"

        "$coreutils/touch" "$config"

        "$awk" -v start="$start" -v end="$end" '
          $0 == start { skip = 1; next }
          $0 == end { skip = 0; next }
          !skip { print }
        ' "$config" > "$stripped"

        "$awk" -v start="$start" -v end="$end" -v source="$source" '
          BEGIN {
            while ((getline line < source) > 0) {
              managed = managed line "\n"
            }
          }
          /^[[:space:]]*\[/ && !inserted {
            printf "%s\n", start
            printf "%s", managed
            printf "%s\n\n", end
            inserted = 1
          }
          { print }
          END {
            if (!inserted) {
              if (NR > 0) {
                print ""
              }
              printf "%s\n", start
              printf "%s", managed
              printf "%s\n", end
            }
          }
        ' "$stripped" > "$next"

        "$coreutils/mv" "$next" "$config"
        "$coreutils/rm" -f "$stripped"
        "$coreutils/chmod" 600 "$config"
      '';
    };
  } // skillLinks;
}
