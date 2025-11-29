# Defines overlays/custom modifications to upstream packages
{
  inputs,
  lib,
  self,
  ...
}:
let
  customLib = import (self.outPath + "/lib") { inherit lib; };

  # Adds custom packages from pkgs directory
  additions =
    final: prev:
    let
      packages = prev.lib.packagesFromDirectoryRecursive {
        callPackage = prev.lib.callPackageWith final;
        directory = customLib.relativeToRoot "pkgs";
      };
    in
    packages;

  # Linux-specific modifications
  linuxModifications = final: prev: prev.lib.optionalAttrs prev.stdenv.isLinux { };

  # General modifications to existing packages
  modifications = final: prev: {
    # Update Spotify to latest version (upstream is outdated)
    # Check for updates: curl -s -H 'X-Ubuntu-Series: 16' "https://api.snapcraft.io/api/v1/snaps/details/spotify?channel=stable" | jq '.revision,.download_sha512,.version'
    spotify = prev.spotify.overrideAttrs (old: rec {
      version = "1.2.74.477.g3be53afe";
      rev = "89";
      src = prev.fetchurl {
        url = "https://api.snapcraft.io/api/v1/snaps/download/pOBIoZ2LrCB3rDohMxoYGnbN14EHOgD7_${rev}.snap";
        hash = "sha512-mn1w/Ylt9weFgV67tB435CoF2/4V+F6gu1LUXY07J6m5nxi1PCewHNFm8/11qBRO/i7mpMwhcRXaiv0HkFAjYA==";
      };
    });
    # Fix dolphin-emu-primehack CMake compatibility issues (stable version only)
    # Unstable has mbedtls library conflicts, so we use stable
    # FIXME: I need this in unstable, stable has broken old pkgs I dont want
    dolphin-emu-primehack = final.stable.dolphin-emu-primehack.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        # Fix CMake minimum version in all vendored dependencies
        echo "Fixing CMake minimum versions in vendored dependencies..."

        # Find all CMakeLists.txt files in Externals
        find Externals -name "CMakeLists.txt" | while read file; do
          # Process each line containing cmake_minimum_required
          if grep -qi "cmake_minimum_required" "$file"; then
            echo "Patching: $file"

            # Create a temporary file for the replacement
            cp "$file" "$file.tmp"

            # Replace any cmake_minimum_required with version < 3.5
            # This handles all formats: 3.2, 3.2.0, 3.0...3.4, etc.
            sed -i -E 's/cmake_minimum_required\s*\(\s*VERSION\s+[0-2](\.[0-9]+)*([^)]*)\)/cmake_minimum_required(VERSION 3.5)/gi' "$file.tmp"
            sed -i -E 's/cmake_minimum_required\s*\(\s*VERSION\s+3\.[0-4](\.[0-9]+)*([^)]*)\)/cmake_minimum_required(VERSION 3.5)/gi' "$file.tmp"

            # Move the temp file back
            mv "$file.tmp" "$file"

            # Show what was changed
            grep -i "cmake_minimum_required" "$file" | head -1
          fi
        done
      '';
    });
  };

  # Stable channel packages
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # Unstable channel packages
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
in
{
  flake.overlays = {
    default =
      final: prev:
      (additions final prev)
      // (modifications final prev)
      // (linuxModifications final prev)
      // (stable-packages final prev)
      // (unstable-packages final prev);
  };
}
