# Axophyte private chat (Pi Web), published by Pangolin as axo.ryot.foo
# through the host-network newt (target localhost:3080, health check /manifest.webmanifest).
# Pangolin SSO is the only login; pi-web binds to loopback without a password.
{
  host,
  hosts,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  user = host.user.name;
  agentDir = "${host.user.homeDirectory}/.local/state/axophyte/pi";
  workspace = "/fast/axophyte";
  axophyte = inputs.axophyte.packages.${pkgs.stdenv.hostPlatform.system}.pi;
  zebes = import ../../../modules/features/agents/home/_zebes-models.nix hosts;

  models = pkgs.writeText "axophyte-models.json" (
    builtins.toJSON {
      providers.zebes = {
        name = "Zebes";
        baseUrl = zebes.baseUrl;
        api = "openai-completions";
        apiKey = "none";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
          maxTokensField = "max_tokens";
        };
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
          // (
            if model ? efforts then
              {
                thinkingLevelMap = {
                  minimal = null;
                  high = null;
                  xhigh = "xhigh";
                };
                compat = {
                  thinkingFormat = "chat-template";
                  chatTemplateKwargs = {
                    enable_thinking."$var" = "thinking.enabled";
                    preserve_thinking = true;
                    reasoning_effort = {
                      "$var" = "thinking.effort";
                      omitWhenOff = true;
                    };
                  };
                };
              }
            else
              {
                thinkingLevelMap = {
                  off = null;
                  minimal = null;
                  low = null;
                  high = null;
                };
                compat.thinkingFormat = "qwen-chat-template";
              }
          )
        ) zebes.models;
      };
    }
  );
in
{
  systemd.tmpfiles.rules = [ "d ${workspace} 0750 ${user} ryot -" ];

  systemd.services.axophyte = {
    description = "Axophyte private chat (Pi Web)";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "docker-hindsight.service"
    ];
    after = [
      "network-online.target"
      "docker-hindsight.service"
    ];
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/${user}"
      "/run/current-system/sw"
      pkgs.pi
      pkgs.git
      pkgs.ripgrep
      pkgs.fd
    ];
    environment = {
      PI_CODING_AGENT_DIR = agentDir;
      PI_WEB_ALLOWED_HOSTS = "axo.ryot.foo";
      PI_WEB_APP_NAME = "Axophyte";
      PI_WEB_SKIP_VERSION_CHECK = "1";
      SHELL = "${pkgs.bashInteractive}/bin/bash";
      AXO_HINDSIGHT_URL = "http://127.0.0.1:8888";
      HINDSIGHT_API_KEY = secrets.service.hindsight.API_KEY;
      TAVILY_API_KEY = secrets.service.discord.axophyte.tavily;
    }
    // lib.filterAttrs (
      name: val:
      builtins.elem name [
        "ANTHROPIC_API_KEY"
        "DEEPSEEK_API_KEY"
        "GEMINI_API_KEY"
      ]
      && val != null
      && val != ""
    ) (secrets.service.models or { });
    serviceConfig = {
      User = user;
      WorkingDirectory = workspace;
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStart = "${lib.getExe pkgs.pi-web} --port 3080 --hostname 127.0.0.1 --no-open";
      # Models and Axo's package are managed; other settings are seeded and then Toph's.
      ExecStartPre = pkgs.writeScript "axophyte-pi-profile" ''
        #!${lib.getExe pkgs.fish}
        set agentDir "${agentDir}"
        ${pkgs.coreutils}/bin/mkdir -p "$agentDir/agents"
        ${pkgs.coreutils}/bin/install -m 0644 "${models}" "$agentDir/models.json"
        for file in "$agentDir/settings.json" "$agentDir/agents/settings.json"
          if not test -f "$file"
            echo '{}' > "$file"
          end
        end
        ${lib.getExe pkgs.jq} --arg pkg "${axophyte}" '{ defaultProvider: "zebes", defaultModel: "qwen3.8-27b-abliterated", defaultThinkingLevel: "low" } + . | .defaultTools = ["+grep", "+find", "+ls", "+codemode", "+tool_search"] | .packages = (((.packages // []) | map(select((type == "string" and endswith("-axophyte-pi")) | not))) + [$pkg])' "$agentDir/settings.json" > "$agentDir/settings.json.tmp"
        and ${pkgs.coreutils}/bin/mv "$agentDir/settings.json.tmp" "$agentDir/settings.json"
        # Pi Web's built-in subagents are off until this switch is set.
        ${lib.getExe pkgs.jq} '{ builtInEnabled: true } + .' "$agentDir/agents/settings.json" > "$agentDir/agents/settings.json.tmp"
        and ${pkgs.coreutils}/bin/mv "$agentDir/agents/settings.json.tmp" "$agentDir/agents/settings.json"
      '';
    };
  };
}
