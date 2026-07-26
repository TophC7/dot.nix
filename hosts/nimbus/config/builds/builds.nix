# Build Pipeline Configuration
#
# Single source of truth for all automated package builds.
# Packages are organized into source groups. Each group declares
# its repo, a group-level update command, and a default expression
# generator. Packages inherit the group default or override with `expr`.
#
# Services generated:
#   mix-builder.service                — Orchestrator (triggered by timer)
#   mix-builder.timer                  — Weekly Monday at 2:00 AM
#   mix-builder-build-<pkg>.service    — Per-package build (started by orchestrator)
#
# Usage:
#   systemctl start mix-builder                         # Full pipeline
#   journalctl -u mix-builder                           # Orchestrator logs
#   journalctl -u mix-builder-build-niri                # Per-package logs
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

  # ── Repository Paths ────────────────────────────────────────────
  mixRepo = "/repo/Nix/mix.nix";
  dotRepo = "/repo/Nix/dot.nix";

  # ── Expression Helpers ──────────────────────────────────────────
  # These define HOW to resolve a package name into a nix derivation.
  # The factory (_lib.nix) doesn't know about overlay vs flake-input —
  # it just receives nix expression strings.

  # Resolve a package from mix.nix via its overlay
  overlay = name: ''
    let
      flake = builtins.getFlake "path:${mixRepo}";
      pkgs = import flake.inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ flake.overlays.default ];
      };
    in pkgs.${name}
  '';

  # Resolve a package from a dot.nix flake input
  dotInput = inputName: attr: ''
    (builtins.getFlake "path:${dotRepo}").inputs.${inputName}.packages.x86_64-linux.${attr}
  '';
in
builds.mkPipeline {
  name = "mix-builder";
  description = "Package Build Pipeline";
  schedule = "Wed *-*-* 04:00:00";
  timeout = "12h";
  retentionDays = 14;
  rootPruneSchedule = "Mon *-*-* 02:30:00"; # before nix.gc at 03:30
  notifyHint = "📝 Run: \\`nix flake update mix-nix\\` in dot.nix";

  groups = [
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # mix.nix — Custom overlay packages
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    {
      name = "mix";
      repo = mixRepo;
      update = "bonk update -p ${mixRepo}";
      mkExpr = overlay;

      packages = [
        # Kernels
        { name = "linux-ryot"; }
        { name = "linux-ryot-zfs"; }
        { name = "linux-ryot-net"; }
        { name = "linuxPackages-ryot-zfs.zfs_cachyos"; }
        { name = "linuxPackages-ryot-zfs.kernel.dev"; }

        # Packages (with per-package update scripts)
        {
          name = "eden";
          update = "fish ${mixRepo}/packages/eden/update.fish";
        }
        {
          name = "gamescope-git";
          update = "fish ${mixRepo}/packages/gamescope-git/update.fish";
        }
        { name = "WiiUDownloader"; }

        # nixpkgs pass-through (no mix.nix override, but resolved via overlay)
        { name = "nh"; }
      ];
    }

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # dot.nix — Flake input packages (no binary cache)
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    {
      name = "dot";
      repo = dotRepo;
      update = "bonk update -p ${dotRepo}";
      mkExpr = name: dotInput name name; # Default: input name = attr name

      packages = [
        {
          name = "fresh";
          expr = dotInput "fresh" "default";
        }
        {
          name = "quickshell";
          expr = dotInput "quickshell" "default";
        }

        {
          name = "dankMaterialShell";
          expr = dotInput "dankMaterialShell" "dms-shell";
        }
        {
          name = "niri";
          expr = dotInput "niri" "niri-unstable";
        }
        {
          name = "vicinae";
          expr = dotInput "vicinae" "default";
        }
      ];
    }
  ];
}
