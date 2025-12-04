{
  secrets,
  ...
}:
let
  networkName = "ai-network";
  open-webui = secrets.service.open-webui;
in
{
  virtualisation.oci-stacks.ollama = {
    containers = {
      ollama = {
        image = "ollama/ollama:rocm";
        environment = {
          HSA_OVERRIDE_GFX_VERSION = "11.0.0";
          OLLAMA_FLASH_ATTENTION = "true";
          OLLAMA_HOST = "0.0.0.0:11434";
          OLLAMA_KEEP_ALIVE = "5m";
          OLLAMA_MAX_LOADED_MODELS = "2";
          OLLAMA_MODELS = "/models";
          OLLAMA_NUM_PARALLEL = "4";
          OLLAMA_ORIGINS = "*";
          PYTORCH_HIP_ALLOC_CONF = "expandable_segments:True";
          PYTORCH_TUNABLEOP_ENABLED = "1";
          TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
        };
        volumes = [
          "/store/ollama/config:/root/.ollama:rw"
          "/store/ollama/models:/models:rw"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network=${networkName}"
          "--network-alias=ollama"
          # GPU passthrough for AMD ROCm
          "--device=/dev/dri:/dev/dri:rwm"
          "--device=/dev/kfd:/dev/kfd:rwm"
          "--security-opt=seccomp:unconfined"
          "--shm-size=17179869184"
          "--memory=34359738368b"
          "--expose=11434"
          # Healthcheck
          ''--health-cmd=["ollama", "list"]''
          "--health-interval=30s"
          "--health-retries=3"
          "--health-start-period=30s"
          "--health-timeout=10s"
        ];
      };

      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        environment = {
          ANONYMIZED_TELEMETRY = "false";
          DEFAULT_MODELS = "llama3.2,mistral,codellama,qwen2.5-coder";
          DEFAULT_USER_ROLE = "user";
          DO_NOT_TRACK = "true";
          ENABLE_COMMUNITY_SHARING = "false";
          ENABLE_RAG_WEB_SEARCH = "true";
          ENABLE_SIGNUP = "false";
          MODEL_FILTER_ENABLED = "false";
          OLLAMA_BASE_URL = "http://ollama:11434";
          RAG_EMBEDDING_MODEL = "nomic-embed-text:latest";
          SCARF_NO_ANALYTICS = "true";
          WEBUI_SECRET_KEY = open-webui.SECRET;
        };
        volumes = [
          "/store/ollama/models:/app/backend/models:ro"
          "/store/open-webui:/app/backend/data:rw"
        ];
        dependsOn = [ "ollama" ];
        log-driver = "journald";
        extraOptions = [
          "--network=${networkName}"
          "--network-alias=open-webui"
          # Healthcheck
          ''--health-cmd=["curl", "-f", "http://localhost:8080/health"]''
          "--health-interval=30s"
          "--health-retries=3"
          "--health-start-period=40s"
          "--health-timeout=10s"
        ];
      };
    };

    network = networkName;
    description = "Ollama AI stack with Open WebUI";
  };
}
