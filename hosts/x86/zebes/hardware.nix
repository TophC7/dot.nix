{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (map lib.custom.relativeToRoot [
      "hosts/global/common/system/fast.nix"
      "hosts/global/common/system/tank.nix"
    ])
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

    # AMD GPU support
    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
    ];
    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];
    extraModulePackages = [ ];

    # Enable ZFS for NVMe pool
    supportedFilesystems = [ "zfs" ];
    zfs.enableUnstable = false;
    zfs.forceImportRoot = false;
    zfs.forceImportAll = true;
  };

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

  fileSystems = {
    # ZFS pool for docker and container storage (2x NVMe in mirror or RAIDZ1)
    "/store" = {
      device = "store/store";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    # TODO: update UUIDs once installed
    # TODO: move os ssd to BTRFS
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

    # Bind-mount Docker and LXC data to /store for NVMe speed
    "/var/lib/docker" = {
      device = "/store/lib/docker";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

    "/var/lib/lxc" = {
      device = "/store/lib/lxc";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;
}
