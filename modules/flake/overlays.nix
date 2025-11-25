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
    # Fix dolphin-emu-primehack CMake compatibility issues (stable version only)
    # Unstable has mbedtls library conflicts, so we use stable
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
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  # Unstable channel packages
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
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
