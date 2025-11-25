{ pkgs }:
let
  inherit (builtins) length concatStringsSep;
  inherit (pkgs) lib cabextract writeShellScriptBin;
  inherit (lib) makeBinPath makeLibraryPath;
in
{
  is64bits ? false,
  wine ? if is64bits then pkgs.wineWowPackages.stable else pkgs.wine,
  wineFlags ? "",
  executable,
  chdir ? null,
  name,
  tricks ? [ ],
  setupScript ? "",
  firstrunScript ? "",
  home ? "",
}:
let
  # Wine executable configuration
  wineBin = "${wine}/bin/wine${if is64bits then "64" else ""}";
  wineArch = if is64bits then "win64" else "win32";

  # Required packages for Wine
  requiredPackages = [
    wine
    cabextract
    pkgs.winetricks
    pkgs.freetype
    pkgs.fontconfig
  ];

  runtimeLibs = [
    pkgs.freetype
    pkgs.fontconfig
    pkgs.pkgsi686Linux.freetype # 32-bit FreeType for Wine
    pkgs.pkgsi686Linux.fontconfig # 32-bit fontconfig for Wine
  ];

  # Wine fonts package for text rendering
  wineFonts = pkgs.winePackages.fonts;

  # Setup commands
  setupHook = ''
    ${wine}/bin/wineboot
  '';

  tricksHook =
    if (length tricks) > 0 then
      let
        tricksStr = concatStringsSep " " tricks;
      in
      ''
        ${pkgs.winetricks}/bin/winetricks ${tricksStr}
      ''
    else
      "";

  # Main wrapper script
  script = writeShellScriptBin name ''
    #!${pkgs.bash}/bin/bash
    set -e

    # ========== Core Configuration ==========
    export APP_NAME="${name}"
    export WINEARCH="${wineArch}"
    export EXECUTABLE="${executable}"

    # ========== Directory Structure ==========
    export WINE_NIX_BASE="$HOME/.wine-nix"
    export WINE_NIX_PROFILES="$WINE_NIX_BASE/PROFILES"
    export WINE_NIX_PREFIXES="$WINE_NIX_BASE/PREFIXES"

    # App-specific directories
    export APP_PROFILE="${if home == "" then "$WINE_NIX_PROFILES/$APP_NAME" else home}"
    export WINEPREFIX="$WINE_NIX_PREFIXES/$APP_NAME"

    # ========== Environment Setup ==========
    export PATH="${makeBinPath requiredPackages}:$PATH"
    export LD_LIBRARY_PATH="${makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH"

    # Override HOME to isolate app data
    export HOME="$APP_PROFILE"

    # ========== Directory Initialization ==========
    echo "🍷 Starting $APP_NAME..."

    mkdir -p "$WINE_NIX_BASE"
    mkdir -p "$WINE_NIX_PROFILES"
    mkdir -p "$WINE_NIX_PREFIXES"
    mkdir -p "$APP_PROFILE"

    # ========== Custom Setup Script ==========
    ${setupScript}

    # ========== Wine Prefix Initialization ==========
    if [ ! -d "$WINEPREFIX" ]; then
      echo "🍷 First run detected. Setting up Wine prefix..."

      # Initialize wine prefix
      ${setupHook}
      wineserver -w

      # Apply winetricks if configured
      ${tricksHook}

      # Link user directory to app profile
      rm -rf "$WINEPREFIX/drive_c/users/$USER"
      ln -s "$APP_PROFILE" "$WINEPREFIX/drive_c/users/$USER"

      # Run first-time setup script
      ${firstrunScript}

      echo "🍷 Wine prefix setup complete"
    fi

    # ========== Working Directory ==========
    ${
      if chdir != null then
        ''
          # Change to specified working directory
          cd "${chdir}"
        ''
      else
        ""
    }

    # ========== REPL Mode (for debugging) ==========
    if [ -n "$REPL" ]; then
      echo "🍷 Entering REPL mode. Type 'exit' to quit."
      echo "  WINEPREFIX=$WINEPREFIX"
      echo "  HOME=$HOME"
      bash
      exit 0
    fi

    # ========== Run Application ==========
    echo "🍷 Launching $APP_NAME..."
    ${wineBin} ${wineFlags} "$EXECUTABLE" "$@"

    # Wait for wineserver to finish
    wineserver -w
  '';
in
script
