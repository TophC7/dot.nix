# Package Builder Service
#
# Builds expensive mix.nix packages weekly on Monday at 2:30 AM.
# These packages have long build times and benefit from caching.
#
{
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
let
  builds = import ./_lib.nix { inherit lib pkgs secrets host; };
in
builds.mkBuildService {
  name = "package-builder";
  description = "Build mix.nix packages";
  repoPath = "/repo/Nix/mix.nix";

  # Expensive packages only - ordered by build time
  packages = [
    "eden" # VERY HIGH: 40+ deps, 30+ min build
    "gamescope-git" # HIGH: C/C++, 10-15 min
    "WiiUDownloader" # MEDIUM: Go + GTK3, 5 min
  ];

  schedule = "Mon *-*-* 02:30:00"; # Weekly Monday at 2:30 AM (after kernels)
  timeout = "4h";

  # Update all flake inputs
  updateFlakeLock = true;
  flakeInput = null; # null = all inputs

  # Run after kernel-builder completes (prevents concurrent builds)
  after = "kernel-builder";

  emoji = "📦";
}
