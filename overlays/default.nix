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
      version = "20250630";
      src = prev.fetchFromGitLab {
        owner = "kernel-firmware";
        repo = "linux-firmware";
        rev = "e2dad11e8d4b169fdeac476d694d6ef8f2d3b5bf";
        hash = "sha256-AvSsyfKP57Uhb3qMrf6PpNHKbXhD9IvFT1kcz5J7khM=";
      };
    });

    ghostty = prev.ghostty.overrideAttrs (_: {
      preBuild = ''
        shopt -s globstar
        sed -i 's/^const xev = @import("xev");$/const xev = @import("xev").Epoll;/' **/*.zig
        shopt -u globstar
      '';
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
