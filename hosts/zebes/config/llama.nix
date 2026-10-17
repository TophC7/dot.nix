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
    # ROCm, not Vulkan: Vulkan's flash attention over the q8_0 KV cache collapses
    # with depth (Qwen3.8-27B prompt processing 283 → 69 t/s at 32k), while ROCm
    # holds 752 → 537 t/s and decodes ~15% faster on the RX 7900 GRE.
    package = pkgs.llama-cpp-rocm;
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

  # Runtime PM suspends the idle dGPU after 5 s, and suspending first evicts every
  # VRAM buffer to system RAM: the resident model (~15 GB) sat in GTT between
  # requests, squeezing RAM into swap and slowing prompt processing after resume.
  boot.kernelParams = [ "amdgpu.runpm=0" ];

  # Quieter llama-server. Measured on a 14k-token prompt with greedy output:
  #   stock (244 W):           695 t/s prompt, 26.5 t/s decode, ~240 W, 91 °C junction
  #   219 W cap (driver floor): 677 t/s prompt, 26.2 t/s decode, ~212 W, 85 °C junction
  #   + 2000 MHz core clock:    646 t/s prompt, 25.2 t/s decode, ~185 W, 79 °C junction
  # Overdrive (the driver's boot mask plus bit 0x4000) is what allows the clock cap.
  # No undervolt: -50 to -75 mV changed greedy output on long prompts that stock
  # voltage reproduced exactly, i.e. silent compute errors.
  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xfff7ffff";
  };
  systemd.services.gpu-tune = {
    description = "Apply RX 7900 GRE clock and power caps";
    wantedBy = [ "multi-user.target" ];
    before = [ "llama-cpp.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "gpu-tune" ''
        #!${lib.getExe pkgs.fish}
        set dev /sys/bus/pci/devices/0000:09:00.0
        set cap $dev/hwmon/hwmon*/power1_cap
        echo 219000000 > $cap
        echo "s 1 2000" > $dev/pp_od_clk_voltage
        echo c > $dev/pp_od_clk_voltage
      '';
    };
  };

  systemd.services.llama-cpp = {
    environment = {
      HOME = "/var/lib/llama-cpp";
      XDG_CACHE_HOME = "/var/cache/llama-cpp";
    };
    serviceConfig = {
      RestartSec = lib.mkForce "5s";
      SupplementaryGroups = [ "render" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];
}
