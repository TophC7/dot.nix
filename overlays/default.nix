# Defines overlays/custom modifications to upstream packages

{ inputs, ... }:
let
  # Adds my custom packages
  additions =
    final: prev:
    let
      packages = prev.lib.packagesFromDirectoryRecursive {
        callPackage = prev.lib.callPackageWith final;
        directory = ../pkgs;
      };
    in
    packages;

  linuxModifications = final: prev: prev.lib.mkIf final.stdenv.isLinux { };

  modifications = final: prev: {
    ## FIXME: Workaround, amd drivers are borked on current nixpkgs-unstable
    linux-firmware = prev.linux-firmware.overrideAttrs (old: rec {
      version = "20250509";
      src = prev.fetchzip {
        url = "https://cdn.kernel.org/pub/linux/kernel/firmware/linux-firmware-${version}.tar.xz";
        hash = "sha256-0FrhgJQyCeRCa3s0vu8UOoN0ZgVCahTQsSH0o6G6hhY=";
      };
    });
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

in
{
  default =
    final: prev:

    (additions final prev)
    // (modifications final prev)
    // (linuxModifications final prev)
    // (stable-packages final prev)
    // (unstable-packages final prev);
}
