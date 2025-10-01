# ZFS Configuration for nimbus

This document contains the non-declarative ZFS properties that must be set manually to avoid boot issues and emergency mode.

## Problem
When ZFS datasets have `canmount=on` (default), they auto-mount when imported. If NixOS also defines these mounts in `fileSystems`, systemd tries to mount them again, causing "mountpoint busy" errors and triggering emergency mode.

## Solution
Set `canmount=noauto` on datasets to let systemd handle mounting through the `fileSystems` configuration.

## Required ZFS Properties

These properties must be set manually after pool creation or system rebuild:

```bash
# Parent pools - should not mount
sudo zfs set mountpoint=none tank
sudo zfs set canmount=off tank
sudo zfs set mountpoint=none fast
# fast can have canmount=on since mountpoint=none prevents mounting

# Datasets - let systemd handle mounting
sudo zfs set canmount=noauto tank/tank
sudo zfs set mountpoint=/tank tank/tank

sudo zfs set canmount=noauto fast/fast
sudo zfs set mountpoint=/fast fast/fast

sudo zfs set canmount=noauto fast/repo
sudo zfs set mountpoint=/repo fast/repo
```

## Verification

Check current settings:
```bash
zfs get canmount,mountpoint,mounted tank tank/tank fast fast/fast fast/repo
```

Expected output:
- Parent pools (`tank`, `fast`): `mountpoint=none`, `mounted=no`
- Datasets: `canmount=noauto`, correct mountpoints, `mounted=yes` (after boot)

## Pool Structure

- **tank**: 4x HDD RAIDZ1 with SSD special vdev for metadata
  - `tank/tank`: Main storage dataset mounted at `/tank`
  
- **fast**: SSD mirror pool  
  - `fast/fast`: Fast storage mounted at `/fast`
  - `fast/repo`: Repository storage mounted at `/repo`
  - `/fast/lib/docker`: Bind-mounted to `/var/lib/docker`
  - `/fast/lib/lxc`: Bind-mounted to `/var/lib/lxc`

## Recovery

If system enters emergency mode:
1. Enter root password when prompted
2. Check mount status: `zfs mount`
3. Set properties as shown above
4. Exit to continue boot