{
  pkgs,
  lib,
  ...
}:
let
  runtimeLibs = with pkgs; [
    ## native versions
    glfw3-minecraft
    openal

    ## openal
    alsa-lib
    libjack2
    libpulseaudio
    pipewire

    ## glfw
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXxf86vm

    udev # oshi

    vulkan-loader # VulkanMod's lwjgl
    
    freetype
    fontconfig
    flite
  ];
in
{

  programs.nix-ld.libraries = runtimeLibs;

  environment.variables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;
  };
}
