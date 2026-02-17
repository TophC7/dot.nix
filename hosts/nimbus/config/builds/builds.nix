# Build Pipeline Configuration
#
# Single source of truth for all automated package builds.
# Packages are built sequentially in the order defined below.
# Each package can optionally define an updateScript to prepare
# its flake inputs before the cache check.
#
# Services generated:
#   mix-builder.service   — Pipeline (triggered by timer)
#   mix-builder.timer     — Weekly Monday at 2:00 AM
#
# Usage:
#   systemctl start mix-builder       # Full pipeline run
#   journalctl -u mix-builder         # View logs
#
{
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
let
  builds = import ./_lib.nix {
    inherit
      lib
      pkgs
      secrets
      host
      ;
  };
in
let
  repoPath = "/repo/Nix/mix.nix";
in
builds.mkPipeline {
  name = "mix-builder";
  description = "mix.nix Build Pipeline";
  inherit repoPath;
  schedule = "Mon *-*-* 02:00:00"; # Weekly Monday at 2:00 AM
  timeout = "10h";

  packages = [
    # ── Kernels ────────────────────────────────────────────────
    # First kernel entry runs bonk to update all flake inputs.
    # Remaining kernel builds use the already-updated input.
    {
      name = "linux-ryot";
      updateScript = "bonk update -p ${repoPath}";
    }
    { name = "linux-ryot-zfs"; }
    { name = "linux-ryot-net"; }
    { name = "linuxPackages-ryot-zfs.zfs_cachyos"; }
    { name = "linuxPackages-ryot-zfs.kernel.dev"; }

    # ── Packages ───────────────────────────────────────────────
    # Update scripts fetch latest sources and update JSON manifests.
    {
      name = "eden";
      updateScript = "fish ${repoPath}/packages/eden/update.fish";
    }
    {
      name = "gamescope-git";
      updateScript = "fish ${repoPath}/packages/gamescope-git/update.fish";
    }
    { name = "WiiUDownloader"; }
  ];
}
