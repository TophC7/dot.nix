# Hindsight agent memory (vectorize-io/hindsight, embedded Postgres) shared by OMP on every
# agents host and the Axophyte Pi Web chat. API on :8888 (LAN, API-key auth); control plane on
# localhost:9999, published by Pangolin as memory.ryot.foo through the host-network newt
# (health check /api/health). Extraction runs on Zebes' resident llama.cpp model.
{ hosts, secrets, ... }:
let
  key = secrets.service.hindsight.API_KEY;
in
{
  virtualisation.oci-stacks.hindsight = {
    network.enable = false;
    containers.hindsight = {
      image = "ghcr.io/vectorize-io/hindsight:1.0.0";
      environment = {
        HINDSIGHT_API_HOST = "0.0.0.0";
        HINDSIGHT_API_PORT = "8888";
        HINDSIGHT_API_TENANT_EXTENSION = "hindsight_api.extensions.builtin.tenant:ApiKeyTenantExtension";
        HINDSIGHT_API_TENANT_API_KEY = key;
        HINDSIGHT_CP_HOSTNAME = "localhost";
        HINDSIGHT_CP_PORT = "9999";
        HINDSIGHT_CP_DATAPLANE_API_URL = "http://localhost:8888";
        HINDSIGHT_CP_DATAPLANE_API_KEY = key;

        # One request at a time: Zebes' llama-server runs a single slot shared with
        # Axophyte (Discord and Pi Web). Qwen3.8's template honors enable_thinking = false
        # (see modules/features/agents/home/_zebes-models.nix), so thinking stays off.
        HINDSIGHT_API_LLM_PROVIDER = "openai";
        HINDSIGHT_API_LLM_BASE_URL = "http://${hosts.zebes.ip}:11434/v1";
        HINDSIGHT_API_LLM_API_KEY = "none";
        HINDSIGHT_API_LLM_MODEL = "qwen3.8-27b-abliterated";
        HINDSIGHT_API_LLM_EXTRA_BODY = builtins.toJSON { chat_template_kwargs.enable_thinking = false; };
        HINDSIGHT_API_LLM_MAX_CONCURRENT = "1";
        HINDSIGHT_API_LLM_TIMEOUT = "600";
        HINDSIGHT_API_REFLECT_LLM_TIMEOUT = "300";
        HINDSIGHT_API_RETAIN_MAX_COMPLETION_TOKENS = "32000";
        HINDSIGHT_API_EMBEDDINGS_LOCAL_FORCE_CPU = "true";
        HINDSIGHT_API_RERANKER_LOCAL_FORCE_CPU = "true";
      };
      volumes = [ "/fast/hindsight:/home/hindsight/.pg0:rw" ];
      log-driver = "journald";
      extraOptions = [ "--network=host" ];
    };
    description = "Hindsight agent memory";
  };
  networking.firewall.allowedTCPPorts = [ 8888 ];
  systemd.tmpfiles.rules = [ "d /fast/hindsight 0750 1000 ryot -" ];
}
