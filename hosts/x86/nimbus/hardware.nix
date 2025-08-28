{
  pkgs,
  inputs,
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
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

    # Use the cachyos kernel for better performance
    kernelPackages = pkgs.linuxPackages_cachyos;

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

    # Enable ZFS
    supportedFilesystems = [ "zfs" ];
    zfs.enableUnstable = false;
    zfs.forceImportRoot = false;
    zfs.forceImportAll = true;
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

  fileSystems = {

    "/tank" = {
      device = "tank/tank"; # 4x HDD RAIDZ1 pool
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    "/fast" = {
      device = "fast/fast"; # 2x SSD RAIDZ1 or mirror
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    # Note: The tank pool has a special vdev for metadata that's part of the pool structure

    # TODO: update UUIDs once installed
    "/" = {
      device = "/dev/disk/by-uuid/YOUR-ROOT-UUID";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;
}
