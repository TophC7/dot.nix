{
  pkgs,
  lib,
  fetchurl,
  unzip,
  stdenv,
  ...
}:
let
  wineAppWrapper = pkgs.callPackage ../wine-app-wrapper.nix { };

  # 8BitDo Ultimate Software
  updaterZip = fetchurl {
    url = "https://download.8bitdo.com/Ultimate-Software/8BitDo_Ultimate_Software_V2_Windows_V1.27.zip?00";
    sha256 = "sha256-5ITFq/qWQN7vm3tC3NRX6AYRENNNFnte+/P3HT4/SGk=";
  };

  # Extract the updater from the ZIP
  updaterSrc = stdenv.mkDerivation {
    name = "8bitdo-ultimate-software-extracted";
    src = updaterZip;
    nativeBuildInputs = [ unzip ];
    unpackPhase = ''
      unzip $src
    '';
    installPhase = ''
      mkdir -p $out
      # Copy ALL files from the extracted subdirectory (exe needs its DLLs and configs)
      cp -r 8BitDo_Ultimate_Software_V2_V1.27/* $out/
    '';
  };
in
wineAppWrapper {
  name = "8bitdo-updater";
  is64bits = false;
  wine = pkgs.wineWowPackages.waylandFull;
  executable = "${updaterSrc}/8BitDo Ultimate Software V2.exe";

  # Let winetricks handle fonts
  tricks = [
    "corefonts" # Basic Windows fonts
  ];

  # Additional setup after winetricks
  firstrunScript = ''
    # Disable SDL mode in winebus (prevents firmware updater from accessing device)
    # This is done via registry: HKLM\System\CurrentControlSet\Services\winebus
    cat >> "$WINEPREFIX/system.reg" << 'EOF'

    [System\\CurrentControlSet\\Services\\winebus]
    "Enable SDL"=dword:00000000
    EOF

    echo "8BitDo Updater setup complete!"
    echo "Make sure your controller is in bootloader mode (press LB+RB and connect via USB)"
  '';
}
