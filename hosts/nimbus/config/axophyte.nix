# Axophyte private chat (DeepSeek Harness web UI), published by Pangolin as axo.ryot.foo
# through the host-network newt (target localhost:3080, health check /manifest.webmanifest).
# Pangolin SSO is the login: Pangolin adds X-Dsh-Proxy-Secret to proxied requests and
# dsh accepts it in place of its per-process token.
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
  domain = "axo.ryot.foo";
  port = "3080";
  axophyte = inputs.axophyte.packages.${pkgs.stdenv.hostPlatform.system}.dsh;

  # Pangolin SSO is this deployment's login. Pangolin adds X-Dsh-Proxy-Secret to every
  # proxied request (resource → Proxy → Custom Headers) and dsh accepts it in place of
  # its per-process token cookie; local processes without the secret still face that
  # token. dsh also keeps Settings browser-only on non-loopback pages, so the public
  # hostname counts as local for persistence.
  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh.overrideAttrs (old: {
    postInstall = old.postInstall + ''
      lib=$out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-client-connection/lib
      substituteInPlace $lib/index.js --replace-fail 'isAuthenticated(request) {' '${''
        isAuthenticated(request) {
        		const proxySecret = process.env.DSH_PROXY_SECRET, presented = header(request.headers, "x-dsh-proxy-secret");
        		if (proxySecret && presented !== void 0 && tokenMatches(presented, proxySecret)) return true;''}'
      substituteInPlace $lib/client.js --replace-fail \
        'isLoopbackHostname(pageLocation.hostname),' \
        'isLoopbackHostname(pageLocation.hostname) || pageLocation.hostname === "${domain}",'
    '';
  });
  zebes = import ../../../modules/features/agents/home/_zebes-models.nix hosts;

  # pi-ai route for llama-server. Its OpenAI client insists on some credential, so
  # a dummy Authorization header stands in. Qwen3.8 efforts travel as template
  # kwargs (pi-ai's built-in qwen-chat-template only toggles enable_thinking).
  zebesRoute = {
    displayName = "Zebes";
    api = "openai-completions";
    baseURL = zebes.baseUrl;
    headers.Authorization = "Bearer none";
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
        input = [
          "text"
          "image"
        ];
      }
      // (
        if model ? efforts then
          {
            reasoningEfforts = {
              off = null;
            }
            // lib.genAttrs model.efforts lib.id;
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
            # Always thinks; one level marks it as a reasoning model for replay.
            reasoningEfforts.medium = "medium";
            compat.thinkingFormat = "qwen-chat-template";
          }
      )
    ) zebes.models;
  };
  seedPatch = (pkgs.formats.yaml { }).generate "axophyte-dsh.seed.yml" [
    {
      id = "llm-pi-ai";
      config.providers.zebes = zebesRoute;
    }
    {
      id = "agent-default-model";
      config = {
        provider = "zebes";
        model = "qwen3.8-27b-abliterated";
        reasoningEffort = "low";
      };
    }
  ];
in
{
  systemd.services.axophyte = {
    description = "Axophyte private chat (DeepSeek Harness web UI)";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "docker-hindsight.service"
    ];
    after = [
      "network-online.target"
      "docker-hindsight.service"
    ];
    # The agent's shells run as Toph: give them his tools, not systemd's bare PATH.
    path = [
      "/run/wrappers"
      "/etc/profiles/per-user/${user}"
      "/run/current-system/sw"
    ];
    environment = {
      DSH_TELEMETRY_MODE = "DISABLED";
      DSH_PROXY_SECRET = secrets.service.axophyte.PROXY_SECRET;
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
      ExecStartPre = pkgs.writeScript "seed-axophyte-profile" ''
        #!${lib.getExe pkgs.fish}
        set patchDir "${host.user.homeDirectory}/.dsh/profiles/web"
        set patchFile "$patchDir/cordis.patch.yml"
        if not test -f "$patchFile"
          ${pkgs.coreutils}/bin/mkdir -p "$patchDir"
          ${pkgs.coreutils}/bin/cp "${seedPatch}" "$patchFile"
        end
      '';
      ExecStart = "${lib.getExe dsh} web --patch ${axophyte}/axo.patch.json --no-open --port ${port} --trusted-host ${domain}";
      User = user;
      WorkingDirectory = host.user.homeDirectory;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
