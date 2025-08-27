{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    openFirewall = true;
    port = 11434;
  };

  # The Ollama environment variables, as mentioned in the comments section
  systemd.services.ollama.serviceConfig = {
    Environment = [ "OLLAMA_HOST=0.0.0.0:11434" ];
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 11436;
    openFirewall = false;
    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      # A saner set of default parameters.
      OLLAMA_CONTEXT_LENGTH = "16384";
      OLLAMA_FLASH_ATTENTION = "True";
    };
  };

  # Add oterm to the systemPackages
  environment.systemPackages = with pkgs; [
    oterm
  ];
}
