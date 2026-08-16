{ gpus, lib, ... }:
{
  imports = lib.fs.scanPaths ./.;

  # Keep Niri and Gamescope on the Intel GPU that owns the display output.
  # Games launched inside Gamescope can still select NVIDIA through Vulkan or PRIME.
  programs = {
    niri.settings.debug.render-drm-device = "/dev/dri/by-path/pci-${gpus.display}-render";
    wayscope.profiles =
      lib.genAttrs
        [
          "default"
          "steam"
          "wayland"
        ]
        (_: {
          options.prefer-vk-device = "8086:9bc8";
        });
  };
}
