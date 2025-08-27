{ lib, ... }:
{
  imports = [ ];

  # Enable ZFS
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.enableUnstable = false;
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = true;

  # ZFS services
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

  fileSystems."/tank" = {
    device = "tank/tank"; # 4x HDD RAIDZ1 pool
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/fast" = {
    device = "fast/fast"; # 2x SSD RAIDZ1 or mirror
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/meta" = {
    device = "meta/meta"; # Special vdev for metadata/small files
    fsType = "zfs";
    options = [ "zfsutil" ];
  };
}
