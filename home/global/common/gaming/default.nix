{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.packages = with pkgs; [
    prismlauncher
    # modrinth-app
  ];
}

# INFO: Example working commands for running gamescope

# gamescope --adaptive-sync --backend sdl --expose-wayland --force-grab-cursor --framerate-limit 120 --immediate-flips --output-height 2160 --output-width 3840 --prefer-output DP-3 --rt -- gamemoderun %command%

# AMD_VULKAN_ICD=RADV RADV_PERFTEST=aco PROTON_USE_D9VK=1 CAP_SYS_NICE=eip gamescope --expose-wayland --backend sdl --framerate-limit 120 --output-height 2160 --output-width 3840 --prefer-vk-device 7550:C0 --rt -F fsr -f --sharpness 4 -- gamemoderun %command%
