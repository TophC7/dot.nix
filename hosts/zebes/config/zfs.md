# ZFS Configuration for zebes

Zebes declares ownership of `/store` through systemd; pool and dataset mountpoints remain provisioning-time ZFS properties.

## Problem
When `store/store` has `canmount=on` (default), `zfs-mount.service` runs `zfs mount -a` in parallel with NixOS's `store.mount`. Both try to mount `/store`, causing conflicts and potentially triggering emergency mode.

## Solution
`zfs-canmount.nix` declares `zfs-enforce-canmount.service`, which sets `canmount=noauto` only on `store/store`. This leaves `store.mount`, generated from `fileSystems."/store"` in `hardware.nix`, as the single mount owner.

Both `zfs-mount.service` and `store.mount` require successful enforcement, ordered as:

`zfs-import-store.service` → `zfs-enforce-canmount.service` → both mount paths.

The oneshot uses Zebes's configured `boot.zfs.package`, runs on boot and when started/restarted during deployment, and remains active after success. A failed property update blocks both mount paths. It does not unmount the live dataset; `zfs mount -a` skips it on subsequent runs. `DefaultDependencies=false` avoids a local-filesystem dependency cycle.

## Required ZFS Properties

Set these properties when provisioning the pool/dataset; ordinary rebuilds do not require manual `canmount=noauto` updates:

```fish
# Parent pool - should not mount
sudo zfs set mountpoint=none store
sudo zfs set canmount=off store

# Dataset - mountpoint must match hardware.nix; canmount=noauto is enforced declaratively
sudo zfs set mountpoint=/store store/store
```

## Verification

Check current settings:
```fish
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
3. Restore provisioning properties as shown above, then run `sudo zfs set canmount=noauto store/store` if enforcement is not yet deployed; otherwise inspect `systemctl status zfs-enforce-canmount.service` and fix its reported failure
4. Exit to continue boot

## Notes

The previous issue was `store/store` had `mountpoint=/mnt/store` while NixOS expected `/store`, causing a mismatch. Always ensure the ZFS mountpoint property matches the path in `hardware.nix`.