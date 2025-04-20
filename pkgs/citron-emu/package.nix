{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = "citron-emu";
  version = "0.6.1-canary-refresh";
  src = fetchTarball {
    url = "https://git.citron-emu.org/Citron/Citron/releases/download/v0.6.1-canary-refresh/Citron-Linux-Canary-Refresh_0.6.1_compatibility.tar.gz";
    sha256 = "sha256:00d2mn2pc51gaz47db15q95gkd6x3566a2a8vc0lhq37jvyfq72r";
  };
  # sourceRoot = ".";
  # nativeBuildInputs = with pkgs; [
  #   gzip
  # ];
  runtimeLibs = with pkgs; [
    qt6.qtbase
    ffmpeg
    libusb1
    libva
    SDL2
    # libGL
    # libGLU
    # libevent
    # libffi
    # libjpeg
    # libpng
    # libstartup_notification
    # libvpx
    # libwebp

    # git
    #   vulkan-headers
    #   vulkan-utility-libraries
    #   boost185
    #   autoconf
    #   fmt
    #   llvm_19
    #   nasm
    #   lz4
    #   nlohmann_json
    # ffmpeg
    # #   qt6.qtbase
    # #   enet
    # libva
    # #   vcpkg
    # #   libopus
    # #   udev

    # stdenv.cc.cc

    # fontconfig
    # libxkbcommon
    # zlib
    # freetype
    # gtk3
    # libxml2
    # dbus
    # xcb-util-cursor
    # alsa-lib
    # libpulseaudio
    # pango
    # atk
    # cairo
    # gdk-pixbuf
    # glib
    # udev
    # libva
    # mesa
    # libnotify
    # cups
    # pciutils
    # ffmpeg
    # libglvnd
    # pipewire
  ];
  # ++ (with pkgs.xorg; [
  #   libxcb
  #   libX11
  #   libXcursor
  #   libXrandr
  #   libXi
  #   libXext
  #   libXcomposite
  #   libXdamage
  #   libXfixes
  #   libXScrnSaver
  # ]);

  nativeBuildInputs =
    with pkgs;
    [
      autoPatchelfHook
      kdePackages.wrapQtAppsHook

      # makeWrapper
      # copyDesktopItems
      # wrapGAppsHook
    ]
    ++ runtimeLibs;

  installPhase = ''
      install -Dm755 $src/citron $out/bin/${pname}
      mkdir -p $out/share/applications
      cat > $out/share/applications/${pname}.desktop <<EOF
    [Desktop Entry]
    Name=Citron Emu
    Exec=${pname}
    Icon=applications-games
    Type=Application
    Categories=Utility;
    Terminal=false
    EOF
  '';
}
