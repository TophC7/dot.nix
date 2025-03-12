{ pkgs, lib, ... }:

# TODO: not really working, might just remove

let
  pname = "fleet";
  version = "1.46.97";

  src = pkgs.fetchurl {
    url = "https://download-cdn.jetbrains.com/fleet/installers/linux_x64/Fleet-${version}.tar.gz";
    sha256 = "a7b66f9faff74f2b8b0143bc588a990304dd8efd3ea20fd8d2754cb064a993f3";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    mv $out/bin/${pname} $out/bin/${pname}
    install -m 444 -D ${appimageContents}/lib/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png
  '';
  # install -m 444 -D ${appimageContents}/ubports-installer.desktop $out/share/applications/${pname}.desktop
  # substituteInPlace $out/share/applications/${pname}.desktop \
  # --replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'

  meta = with lib; {
    description = "Jetbrains Fleet";
    platforms = [ "x86_64-linux" ];
  };
}
