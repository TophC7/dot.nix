{
  hosts,
  pkgs,
  lib,
  ...
}:
let
  yaml = pkgs.formats.yaml { };

  settings = {
    setupVersion = 2;

    # Keep discovery isolated to mostly native OMP sources and OMP-installed plugins.
    disabledProviders = [
      "agent-plugins"
      "agents"
      "claude"
      "claude-plugins"
      "cline"
      "codex"
      "cursor"
      "gemini"
      "github"
      "mcp-json"
      "opencode"
      "ssh-json"
      "vscode"
      "windsurf"
    ];

    modelRoles = {
      default = "google-antigravity/gemini-3.8-flash:high";
      commit = "google-antigravity/gemini-3.8-flash:low";
      plan = "anthropic/claude-fable-5-1:medium";
      smol = "openai-codex/gpt-5.6-luna:xhigh";
      task = "openai-codex/gpt-5.6-sol:high";
      tiny = "openai-codex/gpt-5.3-codex-spark";
      bard = "google-antigravity/gemini-3.8-flash:high";
      designer = "anthropic/claude-opus-5.5:high";
      audit = "openai-codex/gpt-6-astra:low";
    };

    cycleOrder = [
      "default"
      "bard"
      "task"
      "audit"
      "plan"
      "designer"
      "smol"
    ];

    defaultThinkingLevel = "high";

    startup = {
      quiet = true;
      checkUpdate = false;
      changelogMode = "summary";
    };

    symbolPreset = "nerd";
    composer.shape = "claude";
    theme = {
      dark = "dark";
      light = "light";
    };

    statusLine = {
      preset = "default";
      separator = "pipe";
      sessionAccent = true;
      compactThinkingLevel = true;
    };

    terminal.showProgress = true;

    tui = {
      tight = false;
      resizeScrollback = "append";
      textSizing = true;
      hyperlinks = "always";
    };

    display = {
      shimmer = "classic";
      showTokenUsage = true;
      showTurnTime = true;
    };

    hideThinkingBlock = false;
    proseOnlyThinking = true;
    steeringMode = "one-at-a-time";

    tools.approvalMode = "yolo";

    bash = {
      enabled = true;
      direnv = "off";
    };

    eval.py = false;
    python.kernelMode = "session";
    goal.enabled = false;

    task = {
      eager = "default";
      agentModelOverrides.scout = "@bard";
    };

    dev.autoqaConsent = "granted";
    checkpoint.enabled = true;
    github.enabled = true;
    read.renderMarkdown = true;
    memory.backend = "off";
    treeFilterMode = "default";
    marketplace.autoUpdate = "off";
    features.unexpectedStopDetection = "mechanical";
    completion.notify = "on";
    error.notify = "on";
    ask.notify = "on";
  };

  models.providers = {
    # Local inference on Zebes (llama-server, router mode).
    #
    # llama-server serves unauthenticated, and `auth: none` is what waives OMP's
    # apiKey requirement for a custom provider — no placeholder key needed.
    #
    # The private-range baseUrl is load-bearing, not laziness: OMP keys its
    # local-backend compat off a loopback/RFC1918 host — reasoning replay for
    # KV-cache hits across turns, Qwen `preserve_thinking`, no first-event
    # watchdog, a 300s stream idle floor, append-only context. A DNS name would
    # resolve fine and silently lose all of it.
    zebes = {
      baseUrl = "http://${hosts.zebes.ip}:11434/v1";
      api = "openai-completions";
      auth = "none";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
        maxTokensField = "max_tokens";
      };
      models =
        let
          # These templates always think and expose no effort control, so the
          # models carry `reasoning` with no `thinking` block — OMP reads that
          # as "reasoning model, no effort tiers". Pi's `thinkingLevelMap.off`
          # has no counterpart in OMP's schema.
          common = {
            reasoning = true;
            contextWindow = 131072;
            maxTokens = 32768;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          };
          vision = common // {
            input = [
              "text"
              "image"
            ];
          };
        in
        [
          (
            vision
            // {
              id = "qwen3.5-9b-opus-reasoning";
              name = "Qwen3.5/Opus";
            }
          )
          (
            vision
            // {
              id = "qwen3.5-9b-sushi-coder-rl";
              name = "Qwen3.5/Sushi Coder";
            }
          )
          (
            vision
            // {
              id = "qwen3.5-27b-opus-reasoning-v2";
              name = "Qwen3.5/Opus 27B";
            }
          )
          (
            common
            // {
              id = "ornith-1.0-35b";
              name = "Ornith 1.0/35B";
              input = [ "text" ];
            }
          )
        ];
    };
  };

  configFile = yaml.generate "omp-config.yml" settings;
  modelsFile = yaml.generate "omp-models.yml" models;
  emptyJson = pkgs.writeText "omp-empty.json" "{}";

  activation = pkgs.writeShellScript "activate-omp" ''
    set -euo pipefail

    agent_dir="$HOME/.omp/agent"
    plugin_dir="$HOME/.omp/plugins"
    mcp_config="$agent_dir/mcp.json"
    plugin_config="$plugin_dir/package.json"

    ${pkgs.coreutils}/bin/mkdir -p "$agent_dir" "$plugin_dir"
    ${pkgs.coreutils}/bin/install -m 600 ${configFile} "$agent_dir/config.yml"

    mcp_tmp=""
    plugin_tmp=""
    cleanup() {
      [[ -z "$mcp_tmp" ]] || ${pkgs.coreutils}/bin/rm -f "$mcp_tmp"
      [[ -z "$plugin_tmp" ]] || ${pkgs.coreutils}/bin/rm -f "$plugin_tmp"
    }
    trap cleanup EXIT

    mcp_source="$mcp_config"
    if [[ ! -f "$mcp_source" ]]; then
      mcp_source="${emptyJson}"
    fi
    mcp_tmp="$(${pkgs.coreutils}/bin/mktemp "$agent_dir/.mcp.json.XXXXXX")"
    ${pkgs.jq}/bin/jq \
      --arg command "${lib.getExe pkgs.context-mode}" \
      --arg data_dir "$HOME/.omp/context-mode" '
      .mcpServers = (.mcpServers // {}) |
      .mcpServers["context-mode"] = {
        type: "stdio",
        command: $command,
        env: {
          CONTEXT_MODE_PLATFORM: "omp",
          CONTEXT_MODE_DIR: $data_dir
        }
      }
    ' "$mcp_source" > "$mcp_tmp"
    ${pkgs.coreutils}/bin/chmod 600 "$mcp_tmp"
    ${pkgs.coreutils}/bin/mv -f "$mcp_tmp" "$mcp_config"
    mcp_tmp=""

    plugin_source="$plugin_config"
    if [[ ! -f "$plugin_source" ]]; then
      plugin_source="${emptyJson}"
    fi
    plugin_tmp="$(${pkgs.coreutils}/bin/mktemp "$plugin_dir/.package.json.XXXXXX")"
    ${pkgs.jq}/bin/jq --arg source "file:${pkgs.context-mode}" '
      .name = (.name // "omp-plugins") |
      .private = true |
      .dependencies = (.dependencies // {}) |
      .dependencies["context-mode"] = $source
    ' "$plugin_source" > "$plugin_tmp"
    ${pkgs.coreutils}/bin/chmod 600 "$plugin_tmp"
    ${pkgs.coreutils}/bin/mv -f "$plugin_tmp" "$plugin_config"
    plugin_tmp=""

    trap - EXIT
  '';
in
{
  home.packages = [
    pkgs.omp
    pkgs.context-mode
  ];

  home.file = {
    ".omp/plugins/node_modules/context-mode".source = pkgs.context-mode;
    ".omp/agent" = {
      source = ./agent;
      recursive = true;
    };
    ".omp/agent/models.yml".source = modelsFile;
  };

  # OMP rewrites its config and owns mutable MCP/plugin registries at runtime.
  # Reset declared config while preserving unrelated registry entries.
  home.activation.omp = lib.hm.dag.entryAfter [ "writeBoundary" ] "run ${activation}";
}
