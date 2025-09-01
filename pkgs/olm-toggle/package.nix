{
  lib,
  stdenv,
  writeTextDir,
}:

stdenv.mkDerivation rec {
  pname = "olm-toggle";
  version = "1.0.0";

  src = writeTextDir "share/gnome-shell/extensions/olm-toggle@toph/extension.js" (
    builtins.readFile ./extension.js
  );

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/gnome-shell/extensions/olm-toggle@toph
    cp -r $src/share/gnome-shell/extensions/olm-toggle@toph/* $out/share/gnome-shell/extensions/olm-toggle@toph/

    # Add metadata.json
    cp ${./metadata.json} $out/share/gnome-shell/extensions/olm-toggle@toph/metadata.json

    # Install polkit rules
    mkdir -p $out/share/polkit-1/rules.d
    cp ${./polkit.rules} $out/share/polkit-1/rules.d/olm-toggle.rules

    runHook postInstall
  '';

  meta = with lib; {
    description = "GNOME Shell extension to toggle OLM tunneling service";
    homepage = "https://github.com/TophC7/dot.nix/tree/main/pkgs/olm-toggle";
    license = licenses.agpl3Only;
    maintainers = [ "Toph" ];
    platforms = platforms.linux;
  };
}
