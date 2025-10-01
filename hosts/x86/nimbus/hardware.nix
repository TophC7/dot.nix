{
  pkgs,
  inputs,
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = lib.flatten [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  ## Boot ##
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Use ZFS-compatible kernel (automatically selects latest compatible version)
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    initrd = {
      systemd.enable = true;
      verbose = false;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # Enable ZFS and BTRFS
    supportedFilesystems = [
      "zfs"
      "btrfs"
    ];
    zfs.forceImportRoot = true; # Required when forceImportAll is true
    zfs.forceImportAll = true; # Import all pools at boot
  };

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

  # BTRFS services
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  fileSystems = {
    # BTRFS root with subvolumes
    "/" = {
      device = "/dev/disk/by-uuid/66ad2f79-3d7c-459f-8ddb-ae02d68379f7";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/66ad2f79-3d7c-459f-8ddb-ae02d68379f7";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/66ad2f79-3d7c-459f-8ddb-ae02d68379f7";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/66ad2f79-3d7c-459f-8ddb-ae02d68379f7";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/.snapshots" = {
      device = "/dev/disk/by-uuid/66ad2f79-3d7c-459f-8ddb-ae02d68379f7";
      fsType = "btrfs";
      options = [
        "subvol=@snapshots"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/swap" = {
      device = "/dev/disk/by-uuid/66ad2f79-3d7c-459f-8ddb-ae02d68379f7";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
        "ssd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/BA9A-E9A7";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    # ZFS storage pools
    # These datasets have canmount=noauto set, so systemd handles mounting
    # This avoids conflicts with ZFS auto-mounting that cause emergency mode
    "/tank" = {
      device = "tank/tank"; # 4x HDD RAIDZ1 pool with SSD metadata
      fsType = "zfs";
      options = [
        "zfsutil"
        "x-systemd.requires=zfs-import-tank.service"
      ];
    };

    "/fast" = {
      device = "fast/fast"; # SSD mirror pool
      fsType = "zfs";
      options = [
        "zfsutil"
        "x-systemd.requires=zfs-import-fast.service"
      ];
    };

    "/repo" = {
      device = "fast/repo"; # SSD mirror pool (dataset)
      fsType = "zfs";
      options = [
        "zfsutil"
        "x-systemd.requires=zfs-import-fast.service"
      ];
    };

    # Bind mounts for Docker/LXC to ZFS storage (disabled temporarily)
    "/var/lib/docker" = {
      device = "/fast/lib/docker";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

    "/var/lib/lxc" = {
      device = "/fast/lib/lxc";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;

  # Required for ZFS
  networking.hostId = "3c65ffd4"; # Generate with: head -c 8 /etc/machine-id
}
