{ lib, ... }:
{
  imports = [ ];

  # Enable ZFS for NVMe pool
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.enableUnstable = false;
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = true;

  # ZFS services for pool health and snapshots
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      frequent = 2;
      hourly = 6;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
  };

  fileSystems."/store" = {
    device = "store/store";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  # Bind-mount Docker and LXC data to /store for parity and NVMe speed
  fileSystems."/var/lib/docker" = {
    device = "/store/lib/docker";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
  };

  fileSystems."/var/lib/lxc" = {
    device = "/store/lib/lxc";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
  };
}
