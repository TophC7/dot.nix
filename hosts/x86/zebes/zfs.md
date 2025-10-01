# ZFS Configuration for zebes

This document contains the non-declarative ZFS properties that must be set manually to avoid boot issues and emergency mode.

## Problem
When ZFS datasets have `canmount=on` (default), they auto-mount when imported. If NixOS also defines these mounts in `fileSystems`, systemd tries to mount them again, causing conflicts and potentially triggering emergency mode.

## Solution
Set `canmount=noauto` on datasets to let systemd handle mounting through the `fileSystems` configuration.

## Required ZFS Properties

These properties must be set manually after pool creation or system rebuild:

```bash
# Parent pool - should not mount
sudo zfs set mountpoint=none store
sudo zfs set canmount=off store

# Dataset - let systemd handle mounting
sudo zfs set canmount=noauto store/store
sudo zfs set mountpoint=/store store/store
```

## Verification

Check current settings:
```bash
zfs get canmount,mountpoint,mounted store store/store
```

Expected output:
- Parent pool (`store`): `mountpoint=none`, `canmount=off`, `mounted=no`
- Dataset (`store/store`): `canmount=noauto`, `mountpoint=/store`, `mounted=yes` (after boot)

## Pool Structure

- **store**: 2x NVMe mirror pool for high-performance storage
  - `store/store`: Main dataset mounted at `/store`
  - `/store/lib/docker`: Bind-mounted to `/var/lib/docker`
  - `/store/lib/lxc`: Bind-mounted to `/var/lib/lxc`

## Recovery

If system enters emergency mode:
1. Enter root password when prompted
2. Check mount status: `zfs mount`
3. Set properties as shown above
4. Exit to continue boot

## Notes

The previous issue was `store/store` had `mountpoint=/mnt/store` while NixOS expected `/store`, causing a mismatch. Always ensure the ZFS mountpoint property matches the path in `hardware.nix`.