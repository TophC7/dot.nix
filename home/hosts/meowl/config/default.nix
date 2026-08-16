{ gpu, lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  programs = {
    niri.settings.debug.render-drm-device = "/dev/dri/by-path/pci-${gpu.pciAddress}-render";
    wayscope.profiles =
      lib.genAttrs
        [
          "default"
          "steam"
          "wayland"
        ]
        (_: {
          options.prefer-vk-device = gpu.vulkanId;
          unset = [
            "AMD_VULKAN_ICD"
            "DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1"
            "MESA_LOADER_DRIVER_OVERRIDE"
            "RADV_PERFTEST"
          ];
        });
  };
}
