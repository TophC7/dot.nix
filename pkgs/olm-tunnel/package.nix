{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "olm-tunnel";
  version = "1.1.3";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "olm";
    rev = version;
    hash = "sha256-Lv04rPZUz2thSs6/CgIj16YNKgRzeb4M4uGKGhAS4Kc=";
  };

  vendorHash = "sha256-4j7l1vvorcdbHE4XXOUH2MaOSIwS70l8w7ZBmp3a/XQ=";

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  meta = with lib; {
    description = "OLM tunneling client for Pangolin networks";
    homepage = "https://github.com/fosrl/olm";
    license = licenses.agpl3Only;
    maintainers = [ "Toph" ];
    mainProgram = "olm";
    platforms = platforms.linux;
  };
}
