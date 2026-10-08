{
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./bun.lock
      ./src
    ];
  };
  creds = secrets.service.discord.axophyte;
  # Guild ID → Axophyte's forum there, or null for mentions and replies only.
  servers = {
    "900599333538390027" = "1557542849275236372";
    "388046572581289985" = "1557624218861174854";
  };
  prepare = pkgs.writeScript "axophyte-prepare" ''
    #!${lib.getExe pkgs.fish}
    set --local state "$STATE_DIRECTORY"
    # Replace only application files; leave SQLite memory and dependency cache intact.
    ${lib.getExe' pkgs.coreutils "rm"} -rf -- "$state/src"; or exit
    ${lib.getExe' pkgs.coreutils "cp"} -R --remove-destination -- \
      ${src}/src \
      ${src}/package.json \
      ${src}/bun.lock "$state/"; or exit
    ${lib.getExe' pkgs.coreutils "chmod"} -R u+w -- "$state/src"; or exit
    cd "$state"; or exit
    # Registry access is required; no lifecycle scripts or implicit runtime installs.
    exec ${lib.getExe pkgs.bun} install --production --frozen-lockfile --ignore-scripts
  '';
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
      BUN_RUNTIME_TRANSPILER_CACHE_PATH = "0";
      HOME = "/var/lib/axophyte";
      BUN_INSTALL_CACHE_DIR = "/var/lib/axophyte/cache";
    };
    serviceConfig = {
      ExecStartPre = prepare;
      ExecStart = "${lib.getExe pkgs.bun} run --no-install src/main.ts";
      DynamicUser = true;
      StateDirectory = "axophyte";
      StateDirectoryMode = "0700";
      WorkingDirectory = "/var/lib/axophyte";
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "30s";
      TimeoutStartSec = "5min";
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
      # Public internet (Discord, Tavily and the package registry), DNS and llama.cpp only.
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
