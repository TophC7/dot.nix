{
  host,
  lib,
  pkgs,
  ...
}:
let
  port = 11434;
in
{
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override {
      vulkanSupport = true;
    };
    settings = {
      host = host.ip;
      inherit port;

      # Router mode keeps model selection out of this service definition.
      models-preset = "/etc/llama/models.ini";
      models-max = 1;

      # Pi owns tools and UI. llama-server only provides inference transport.
      no-webui = true;
      no-slots = true;
      cors-origins = "localhost";
    };
  };

  systemd.services.llama-cpp = {
    environment = {
      HOME = "/var/lib/llama-cpp";
      XDG_CACHE_HOME = "/var/cache/llama-cpp";
      MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp/mesa_shader_cache";
    };
    serviceConfig.RestartSec = lib.mkForce "5s";
  };

  networking.firewall.allowedTCPPorts = [ port ];
}
