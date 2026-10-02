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

  # The GPU belongs to llama-server alone. Any other Vulkan/ROCm user (even a
  # quick llama-bench over ssh) competes for the 16 GB VRAM, the driver evicts
  # the idle model to system RAM, and the next request stalls ~100 s while it
  # pages back. udev drops the default world access on the compute nodes; only
  # this service gets the `render` group. Root and privileged containers still
  # bypass device permissions.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0660"
    KERNEL=="kfd", GROUP="render", MODE="0660"
  '';

  systemd.services.llama-cpp = {
    environment = {
      HOME = "/var/lib/llama-cpp";
      XDG_CACHE_HOME = "/var/cache/llama-cpp";
      MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp/mesa_shader_cache";
    };
    serviceConfig = {
      RestartSec = lib.mkForce "5s";
      SupplementaryGroups = [ "render" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];
}
