{
  callPackage,
  stdenv,
  lib,
  fetchurl,
}:
let
  protonGeTitle = "Proton-CachyOS";
  protonGeVersions = lib.importJSON ./versions.json;
in
stdenv.mkDerivation {
  name = "proton-cachyos";
  version = "${protonGeVersions.base}.${protonGeVersions.release}";

  src =
    let
      tagName = "cachyos-${protonGeVersions.base}-${protonGeVersions.release}-slr";
      fileName = "proton-cachyos-${protonGeVersions.base}-${protonGeVersions.release}-slr-x86_64.tar.xz";
    in
    fetchurl {
      url = "https://github.com/CachyOS/proton-cachyos/releases/download/${tagName}/${fileName}";
      inherit (protonGeVersions) hash;
    };

  buildCommand =
    ''
      mkdir -p $out/bin
      tar -C $out/bin --strip=1 -x -f $src
    ''
    # Replace the internal name and display name
    + lib.strings.optionalString (protonGeTitle != null) ''
      sed -i -r 's|"proton-cachyos-[^"]*"|"${protonGeTitle}"|g' $out/bin/compatibilitytool.vdf
      sed -i -r 's|"display_name"[[:space:]]*"[^"]*"|"display_name" "${protonGeTitle}"|' $out/bin/compatibilitytool.vdf
    '';

  passthru.updateScript = callPackage ./update.nix { };

  meta = with lib; {
    description = "Compatibility tool for Steam Play based on Wine and additional components. CachyOS fork.";
    homepage = "https://github.com/CachyOS/proton-cachyos";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [
      tophc7
    ];
  };
}
