# Kernel Builder Service
#
# Builds CachyOS kernels weekly on Monday at 2:00 AM.
# Checks for upstream updates and populates the binary cache.
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
  name = "kernel-builder";
  description = "Build CachyOS kernels";
  repoPath = "/repo/Nix/mix.nix";

  packages = [
    # Bare kernels
    "linux-ryot"
    "linux-ryot-zfs"
    "linux-ryot-net"

    # ZFS kernel modules (the expensive part — compiled against each kernel)
    "linuxPackages-ryot-zfs.zfs_cachyos"
    "linuxPackages-ryot-zfs.kernel.dev"
  ];

  schedule = "Mon *-*-* 02:00:00"; # Weekly Monday at 2 AM
  timeout = "6h"; # Kernel builds can take a while

  # Only update the kernel input, not all inputs
  updateFlakeLock = true;
  flakeInput = "nix-cachyos-kernel";

  # Check for upstream updates before building
  upstreamFlake = "github:xddxdd/nix-cachyos-kernel/release";
  upstreamInputName = "nix-cachyos-kernel";

  emoji = "🔧";
}
