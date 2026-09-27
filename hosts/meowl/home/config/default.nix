{ gpu, lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  # Sunshine's KMS capture needs an active scanout while waiting for clients.
  dconf.settings."org/gnome/desktop/session"."idle-delay" = lib.hm.gvariant.mkUint32 0;

  programs.wayscope.profiles =
    lib.genAttrs
      [
        "default"
        "steam"
        "sunshine-eden-720p"
        "sunshine-heroic-720p"
        "sunshine-steam-720p"
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
}
