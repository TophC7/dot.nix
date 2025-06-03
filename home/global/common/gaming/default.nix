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

# CAP_SYS_NICE=eip gamescope --expose-wayland --backend sdl --framerate-limit 144 --output-height 1440 --output-width 2560 --rt -F fsr -f --sharpness 4 -- gamemoderun %command%

# gamescope --expose-wayland --backend sdl --framerate-limit 144 --output-height 1440 --output-width 2560 --prefer-vk-device 7480:CF --prefer-output DP-2 --fullscreen --rt -F fsr --sharpness 4 -- gamemoderun %command%

# CAP_SYS_NICE=eip gamescope --expose-wayland --backend sdl --framerate-limit 160 --output-height 1440 --output-width 2560 --prefer-vk-device 73A5:C0 --prefer-output DP-2 --fullscreen --force-windows-fullscreen --rt -F fsr --sharpness 4 -- gamemoderun %command%

# SDL_VIDEODRIVER=x11 CAP_SYS_NICE=eip gamescope --expose-wayland --backend sdl --framerate-limit 160 --output-height 1440 --output-width 2560 --force-windows-fullscreen -f --prefer-vk-device 73A5:C0 --prefer-output DP-2  -- gamemoderun %command% --use-d3d11

# SteamDeck=1 LD_PRELOAD="" PROTON_ENABLE_NVAPI=1 PROTON_ENABLE_WAYLAND=1 VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait gamemoderun %command%  -PSOCompileMode=1

#SDL_VIDEODRIVER=x11 AMD_VULKAN_ICD=RADV RADV_PERFTEST=aco PROTON_USE_D9VK=1 CAP_SYS_NICE=eip gamescope --expose-wayland --backend sdl --framerate-limit 120 --output-height 2160 --output-width 3840 --prefer-vk-device 7550:C0 --rt -F fsr -f --sharpness 4 -- gamemoderun %command%

#SDL_VIDEODRIVER=x11 AMD_VULKAN_ICD=RADV RADV_PERFTEST=aco PROTON_USE_D9VK=1 CAP_SYS_NICE=eip gamescope --expose-wayland --backend sdl --framerate-limit 120 --output-height 2160 --output-width 3840 --prefer-vk-device 7550:C0 --force-windows-fullscreen -f --prefer-vk-device 73A5:C0 --prefer-output DP-2  -- gamemoderun %command% --use-d3d11
