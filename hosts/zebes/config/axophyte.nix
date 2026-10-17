{
  inputs,
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
let
  axophyte = inputs.axophyte.packages.${pkgs.stdenv.hostPlatform.system}.discord;
  creds = secrets.service.discord.axophyte;
  # Guild ID → Axophyte's forum there, or null for mentions and replies only.
  servers = {
    "900599333538390027" = "1557542849275236372";
    "388046572581289985" = "1557624218861174854";
  };
in
{
  systemd.services.axophyte = {
    description = "Axophyte Discord forum chatbot";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "llama-cpp.service"
    ];
    environment = {
      AXOPHYTE_DISCORD_TOKEN = creds.token;
      AXOPHYTE_TAVILY_KEY = creds.tavily;
      AXOPHYTE_SERVERS = builtins.toJSON servers;
      AXOPHYTE_LLAMA_URL = "http://${host.ip}:11434";
      AXOPHYTE_MODEL = "qwen3.8-27b-abliterated";
      AXOPHYTE_AUTH_FILE = "/var/lib/axophyte/auth.json";
      HOME = "/var/lib/axophyte";
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
      ExecStart = lib.getExe axophyte;
      # Optional overrides/new API keys without adding credentials to the Nix store.
      EnvironmentFile = "-/var/lib/axophyte/providers.env";
      DynamicUser = true;
      StateDirectory = "axophyte";
      StateDirectoryMode = "0700";
      WorkingDirectory = "/var/lib/axophyte";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "30s";
      ProtectHome = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      LockPersonality = true;
      CapabilityBoundingSet = "";
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" ];
      # No MemoryDenyWriteExecute: Bun's JIT needs writable executable pages.
      # Host data the bot never needs; /repo and /tank are Nimbus NFS automounts.
      InaccessiblePaths = [
        "-/repo"
        "-/tank"
        "-/store"
      ];
      # Public internet (Discord, model providers, and Tavily), DNS and llama.cpp only.
      IPAddressDeny = [
        "localhost"
        "link-local"
        "multicast"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10"
      ];
      IPAddressAllow = [
        "10.3.3.1/32" # Zebes DNS resolver (nexus)
        "${host.ip}/32"
      ];
    };
  };
}
