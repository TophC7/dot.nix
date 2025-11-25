{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  gtk3,
  libgcrypt,
  librsvg,
  wrapGAppsHook3,
}:
let
  # db.go file that would normally be downloaded by grabTitles.py
  # This is required for the build and contains title database definitions
  # Run ./update-db.fish to update this file, if ever needed
  db-go = ./db.go;
in
buildGoModule rec {
  pname = "wiiu-downloader";
  version = "2.68";

  src = fetchFromGitHub {
    owner = "Xpl0itU";
    repo = "WiiUDownloader";
    rev = "v${version}";
    hash = "sha256-Xa1Td9BsuZq65N45/9/SvhbtTd0vXw8XIdavTp1i7kU=";
  };

  vendorHash = "sha256-8/UoT+/1PK0yqHfBUllSeia1lX8l2YRz+5BhhViWIp4=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    libgcrypt
    librsvg
  ];

  # Copy the pre-fetched db.go
  preBuild = ''
    cp ${db-go} db.go
    chmod +w db.go
  '';

  # Build flags from the GitHub Actions workflow
  ldflags = [
    "-s"
    "-w"
  ];

  # The main package is in cmd/WiiUDownloader
  subPackages = [ "cmd/WiiUDownloader" ];

  # Install desktop file
  postInstall = ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/wiiudownloader.desktop << EOF
    [Desktop Entry]
    Name=WiiU Downloader
    Comment=Download Wii U games, updates, DLC, and demos from Nintendo's servers
    Exec=${pname}
    Icon=folder-download
    Terminal=false
    Type=Application
    Categories=Game;Utility;
    Keywords=wii;wiiu;nintendo;download;game;
    EOF
  '';

  meta = with lib; {
    description = "GUI application to download Wii U games, updates, DLC, and demos directly from Nintendo's servers";
    homepage = "https://github.com/Xpl0itU/WiiUDownloader";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    mainProgram = "WiiUDownloader";
    platforms = platforms.linux;
  };
}
