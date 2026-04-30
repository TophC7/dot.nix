#
# Codex configuration.
# Keeps mutable Codex state in ~/.codex/config.toml while inserting a small
# Nix-managed block for shared agent behavior.
#
{ pkgs, ... }:
{
  home.file.".codex/AGENTS.md" = {
    source = ./AGENTS.md;
  };

  home.file.".codex/config_source.toml" = {
    text = ''
      # Agent instruction discovery
      project_doc_fallback_filenames = [
        "CLAUDE.md",
        "GEMINI.md",
        "CRUSH.md",
        ".github/copilot-instructions.md",
      ]
      project_doc_max_bytes = 65536

      # Beads workflow context
      hooks.SessionStart = [{ hooks = [{ type = "command", command = "bd prime" }] }]
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
}
