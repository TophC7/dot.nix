##############################################################
#
#  ZFS canmount=noauto Enforcement
#
#  Ensures specific ZFS datasets always have canmount=noauto
#  set, preventing boot failures from systemd mount conflicts.
#
#  When a dataset has canmount=on, ZFS tries to auto-mount it
#  during import, which races with systemd's own mount units
#  defined in hardware.nix. This causes emergency mode on boot.
#
#  This service runs after pool import but before ZFS mounts,
#  enforcing the correct property on every boot.
#
##############################################################

{ pkgs, lib, ... }:

let
  # Datasets that must have canmount=noauto to prevent
  # ZFS auto-mount from conflicting with systemd mount units
  datasets = [
    {
      pool = "tank";
      dataset = "tank/tank";
    }
    {
      pool = "fast";
      dataset = "fast/fast";
    }
    {
      pool = "fast";
      dataset = "fast/repo";
    }
  ];

  # Deduplicate pool names for service dependencies
  pools = lib.unique (map (d: d.pool) datasets);

  # Build the enforcement script
  enforceScript = pkgs.writeShellScript "zfs-enforce-canmount" ''
    set -euo pipefail
    PATH="${
      lib.makeBinPath [
        pkgs.zfs
        pkgs.coreutils
      ]
    }:$PATH"

    ${lib.concatMapStringsSep "\n" (d: ''
      # Enforce canmount=noauto on ${d.dataset}
      if zpool list "${d.pool}" &>/dev/null; then
        current=$(zfs get -H -o value canmount "${d.dataset}" 2>/dev/null || echo "unavailable")
        if [ "$current" = "on" ]; then
          echo "zfs-enforce-canmount: ${d.dataset} has canmount=on, setting to noauto"
          zfs set canmount=noauto "${d.dataset}"
        elif [ "$current" = "noauto" ]; then
          echo "zfs-enforce-canmount: ${d.dataset} already has canmount=noauto"
        else
          echo "zfs-enforce-canmount: ${d.dataset} has canmount=$current (skipping)"
        fi
      else
        echo "zfs-enforce-canmount: pool ${d.pool} not available, skipping ${d.dataset}"
      fi
    '') datasets}
  '';
in
{
  systemd.services.zfs-enforce-canmount = {
    description = "Enforce canmount=noauto on ZFS datasets";
    documentation = [ "https://github.com/openzfs/zfs/issues/9674" ];

    # Run after pools are imported but before ZFS tries to mount
    after = map (p: "zfs-import-${p}.service") pools;
    requires = map (p: "zfs-import-${p}.service") pools;

    # Must complete before ZFS mount and local-fs targets
    before = [
      "zfs-mount.service"
      "local-fs.target"
    ];

    # Run on every boot, as part of the local filesystem setup
    wantedBy = [ "zfs-mount.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = enforceScript;
    };

    unitConfig = {
      # Do not fail boot if this service fails -- log and continue
      FailureAction = "none";
      DefaultDependencies = false;
    };
  };
}
