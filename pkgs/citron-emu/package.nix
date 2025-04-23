{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = "citron-emu";
  version = "0.6.1-canary-refresh";
  src = fetchTarball {
    url = "https://git.citron-emu.org/Citron/Citron/releases/download/v0.6.1-canary-refresh/Citron-Linux-Canary-Refresh_0.6.1_compatibility.tar.gz";
    sha256 = "sha256:00d2mn2pc51gaz47db15q95gkd6x3566a2a8vc0lhq37jvyfq72r";
  };
  runtimeLibs = with pkgs; [
    qt6.qtbase
    ffmpeg
    libusb1
    libva
    SDL2
  ];
  nativeBuildInputs =
    with pkgs;
    [
      autoPatchelfHook
      kdePackages.wrapQtAppsHook
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
