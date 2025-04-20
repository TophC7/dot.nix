{
  pkgs,
  lib,
}:

pkgs.stdenv.mkDerivation {
  pname = "borgtui";
  version = "0.1.0";

  src = ./.; # This expects tui.sh to be in the same directory as this file

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  buildInputs = with pkgs; [
    python3
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${./tui.sh} $out/bin/borgtui
    chmod +x $out/bin/borgtui

    wrapProgram $out/bin/borgtui \
      --prefix PATH : ${lib.makeBinPath [ pkgs.borgbackup ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "A simple TUI for managing Borg repositories";
    # homepage = "https://github.com/toph/borgtui"; # Replace with your actual GitHub repo if you have one
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ "tophc7" ]; # Add your name if you're a Nixpkgs maintainer
  };
}
