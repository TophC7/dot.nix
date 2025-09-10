{ pkgs, lib, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "monocraft-nerd-fonts";
  version = "4.1";

  phases = [ "installPhase" ]; # Removes all phases except installPhase

  src = pkgs.fetchurl {
    url = "https://github.com/IdreesInc/Monocraft/releases/download/v4.1/Monocraft-nerd-fonts-patched.ttc";
    sha256 = "95801bf21826bf8572af3787af82e77ee48df4bfb87e90c4317fcffbe7eaf037";
  };

  # unpackPhase = ":".

  installPhase = ''
    mkdir -p $out/share/fonts/truetype/
    cp -r $src $out/share/fonts/truetype/monocraft-nerd-fonts.ttc
  '';

  meta = with lib; {
    description = "Monocraft Nerd Fonts";
    homepage = "https://github.com/IdreesInc/Monocraft";
    platforms = platforms.all;
  };
}
