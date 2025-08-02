{
  lib,
  appimageTools,
  fetchurl,
  ...
}:
let
  pname = "journey";
  meta = builtins.fromJSON (builtins.readFile ./journey.json);
  version = meta.version;
in
appimageTools.wrapType2 {
  inherit pname version;
  src = fetchurl {
    url = "https://github.com/Journey-Cloud/desktop-app-releases/releases/download/${meta.version}/Journey-Desktop-linux-x86_64_${meta.version}.AppImage";
    sha256 = meta.sha256;
  };

  extraInstallCommands = ''
    # Create desktop entry from scratch
    mkdir -p $out/share/applications
    cat > $out/share/applications/${pname}.desktop << EOF
    [Desktop Entry]
    Name=Journey
    Comment=A beautiful cross-platform journal app
    Exec=${pname}
    Icon=com.github.thejambi.dayjournal
    Terminal=false
    Type=Application
    Categories=Office;Utility;
    Keywords=journal;diary;notes;writing;
    EOF
  '';

  meta = with lib; {
    description = "A beautiful cross-platform journal app";
    homepage = "https://journey.cloud/";
    license = licenses.unfree;
    maintainers = with maintainers; [ toph ];
    platforms = [ "x86_64-linux" ];
  };
}
