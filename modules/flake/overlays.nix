# Defines overlays/custom modifications to upstream packages
{ inputs, lib, self, ... }:
let
  customLib = import (self.outPath + "/lib") { inherit lib; };

  # Adds custom packages from pkgs directory
  additions = final: prev:
    let
      packages = prev.lib.packagesFromDirectoryRecursive {
        callPackage = prev.lib.callPackageWith final;
        directory = customLib.relativeToRoot "pkgs";
      };
    in
    packages;

  # Linux-specific modifications
  linuxModifications = final: prev:
    prev.lib.optionalAttrs prev.stdenv.isLinux { };

  # General modifications to existing packages
  modifications = final: prev: {
    # Add any package overrides here
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
    default = final: prev:
      (additions final prev)
      // (modifications final prev)
      // (linuxModifications final prev)
      // (stable-packages final prev)
      // (unstable-packages final prev);
  };
}