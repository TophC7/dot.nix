{
  hosts,
  secrets ? { },
  pkgs,
  lib,
  ...
}:
let
  yaml = pkgs.formats.yaml { };
  json = pkgs.formats.json { };
  deepseekApiKey = secrets.service.models.DEEPSEEK_API_KEY or null;
  geminiApiKey = secrets.service.models.GEMINI_API_KEY or null;

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
      "vscode"
      "windsurf"
    ];

    modelRoles = {
      default = "google-antigravity/gemini-3.8-flash:high";
      commit = "google-antigravity/gemini-3.8-flash:low";
      plan = "anthropic/claude-opus-5-5:high";
      smol = "openai-codex/gpt-6-luna:xhigh";
      task = "openai-codex/gpt-6.1-sol:high";
      advisor = "anthropic/claude-opus-5-5:medium";
      bard = "google-antigravity/gemini-3.8-flash:high";
      claude = "anthropic/claude-opus-5-5:high";
      codex = "openai-codex/gpt-6.1-sol:high";
    };

    cycleOrder = [
      "default"
      "bard"
      "claude"
      "codex"
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
      allowCompoundCommands = true;
    };

    lsp = {
      diagnosticsOnEdit = true;
      formatOnWrite = true;
    };

    eval.py = false;
    python.kernelMode = "session";
    goal.enabled = false;

    task = {
      eager = "preferred";
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
    secrets.enabled = true;
  };

  models.providers =
    lib.optionalAttrs (deepseekApiKey != null && deepseekApiKey != "") {
      deepseek = {
        apiKey = deepseekApiKey;
      };
    }
    // lib.optionalAttrs (geminiApiKey != null && geminiApiKey != "") {
      google = {
        apiKey = geminiApiKey;
      };
    }
    // {
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
      zebes =
        let
          zebes = import ../_zebes-models.nix hosts;
        in
        {
          inherit (zebes) baseUrl;
          api = "openai-completions";
          auth = "none";
          compat = {
            supportsDeveloperRole = false;
            supportsReasoningEffort = false;
            maxTokensField = "max_tokens";
          };
          # Models without efforts carry `reasoning` and no `thinking` block: OMP
          # reads that as "reasoning model, no effort tiers".
          models = map (
            model:
            {
              inherit (model) id name contextWindow;
              inherit (zebes) maxTokens;
              reasoning = true;
              input = [
                "text"
                "image"
              ];
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
            // lib.optionalAttrs (model ? efforts) {
              thinking = {
                mode = "effort";
                inherit (model) efforts;
                defaultLevel = "medium";
                requiresEffort = false;
              };
              compat = {
                thinkingFormat = "qwen-chat-template";
                qwenTemplateReasoningEffort = true;
              };
            }
          ) zebes.models;
        };
    };
  hostDescriptions = {
    nexus = "Network router & gateway";
    zebes = "Local LLM server and misc containers";
    nimbus = "NAS";
    rune = "Primary desktop";
    norion = "Work laptop";
    meowl = "Streaming Desktop";
    caenus = "Cloud VPS ingress (Oracle ARM64, Rathole, WireGuard)";
    vm = "Disposable sandbox VM";
  };

  resolveHostAddress =
    name: h:
    if h.ip != null then
      h.ip
    else if name == "caenus" && (secrets.service.caenus.ip or null) != null then
      secrets.service.caenus.ip
    else
      name;

  enabledHosts = lib.filterAttrs (_: h: h.enable or true) hosts;

  sshHosts = lib.mapAttrs (name: h: {
    host = resolveHostAddress name h;
    username = if builtins.isString h.user then h.user else h.user.name or "toph";
    description =
      hostDescriptions.${name} or (if h.isServer or false then "NixOS server" else "NixOS desktop");
  }) enabledHosts;

  configFile = yaml.generate "omp-config.yml" settings;
  modelsFile = yaml.generate "omp-models.yml" models;
  emptyJson = pkgs.writeText "omp-empty.json" "{}";
  sshFile = json.generate "omp-ssh.json" {
    hosts = sshHosts;
  };

  activation = pkgs.writeShellScript "activate-omp" ''
    set -euo pipefail

    agent_dir="$HOME/.omp/agent"
    plugin_dir="$HOME/.omp/plugins"
    ssh_config="$agent_dir/ssh.json"
    mcp_config="$agent_dir/mcp.json"
    plugin_config="$plugin_dir/package.json"

    ${pkgs.coreutils}/bin/mkdir -p "$agent_dir" "$plugin_dir"
    ${pkgs.coreutils}/bin/install -m 600 ${configFile} "$agent_dir/config.yml"

    ssh_tmp=""
    mcp_tmp=""
    plugin_tmp=""
    cleanup() {
      [[ -z "$ssh_tmp" ]] || ${pkgs.coreutils}/bin/rm -f "$ssh_tmp"
      [[ -z "$mcp_tmp" ]] || ${pkgs.coreutils}/bin/rm -f "$mcp_tmp"
      [[ -z "$plugin_tmp" ]] || ${pkgs.coreutils}/bin/rm -f "$plugin_tmp"
    }
    trap cleanup EXIT

    ssh_source="$ssh_config"
    if [[ ! -f "$ssh_source" ]]; then
      ssh_source="${emptyJson}"
    fi
    ssh_tmp="$(${pkgs.coreutils}/bin/mktemp "$agent_dir/.ssh.json.XXXXXX")"
    ${pkgs.jq}/bin/jq -s '
      .[0] * .[1]
    ' "$ssh_source" "${sshFile}" > "$ssh_tmp"
    ${pkgs.coreutils}/bin/chmod 600 "$ssh_tmp"
    ${pkgs.coreutils}/bin/mv -f "$ssh_tmp" "$ssh_config"
    ssh_tmp=""
    mcp_source="$mcp_config"
    if [[ ! -f "$mcp_source" ]]; then
      mcp_source="${emptyJson}"
    fi
    mcp_tmp="$(${pkgs.coreutils}/bin/mktemp "$agent_dir/.mcp.json.XXXXXX")"
    ${pkgs.jq}/bin/jq \
      --arg ctx_command "${lib.getExe pkgs.context-mode}" \
      --arg data_dir "$HOME/.omp/context-mode" \
      --arg rea_command "${lib.getExe pkgs.rea}" '
      .mcpServers = (.mcpServers // {}) |
      .mcpServers["context-mode"] = {
        type: "stdio",
        command: $ctx_command,
        env: {
          CONTEXT_MODE_PLATFORM: "omp",
          CONTEXT_MODE_DIR: $data_dir
        }
      } |
      .mcpServers["rea"] = {
        type: "stdio",
        command: $rea_command,
        args: [ "mcp" ]
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
    pkgs.rea
  ];

  home.sessionVariables = {
    PUPPETEER_EXECUTABLE_PATH = "${lib.getExe pkgs.helium}";
  };

  home.file = {
    ".agents/skills/reverse-engineer-anything".source = pkgs.rea.passthru.skill;
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
