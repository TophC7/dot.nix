{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "olm-tunnel";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "fosrl";
    repo = "olm";
    rev = version;
    hash = "sha256-/sDWsWOMgDcBYerBbxKWMfWlOUaeQeKQ+OIcE7LJg00=";
  };

  vendorHash = "sha256-DqZU64jwg2AHmze1oWOmDgltB+k1mLSHQyAxnovLaVo=";

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
