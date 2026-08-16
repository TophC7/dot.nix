{
  flakeRoot,
  gpus,
  host,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    ## Meowl Specific Imports ##
    (lib.fs.scanPaths ./.)

    ## Additional Imports ##
    (map (lib.fs.relativeTo flakeRoot) [
      "modules/home/common/gaming"
      "modules/home/common/xdg.nix"
      "modules/home/common/zen.nix"
    ])
  ];

  home.packages = [
    inputs.bedrock-on-linux.packages.${host.system}.default
  ];

  monitors = [
    {
      name = "HDMI-A-3";
      primary = true;
      width = 2560;
      height = 1440;
      refreshRate = 60;
      x = 0;
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
    }
  ];

  # Keep composition on the GPU that owns the virtual output; games still
  # select the NVIDIA GPU through Vulkan or PRIME render offload.
  programs.niri.settings.debug.render-drm-device = "/dev/dri/by-path/pci-${gpus.display}-render";
}
