{ lib, pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "axophyte";
  version = "0.1.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./bun.lock
      ./src
    ];
  };
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontBuild = true;
  # Dependencies, typechecking and tests are handled outside the Nix build.
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/axophyte" "$out/bin"
    cp -R package.json bun.lock src "$out/lib/axophyte/"
    makeWrapper ${lib.getExe pkgs.bun} "$out/bin/axophyte" \
      --add-flags 'run --no-install "$STATE_DIRECTORY/src/main.ts"'
    runHook postInstall
  '';
  meta.mainProgram = "axophyte";
}
