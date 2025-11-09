{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = lib.flatten [
    (modulesPath + "/installer/scan/not-detected.nix")
    # (map lib.custom.relativeToRoot [
    # ])
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
        "igc" # Intel 2.5G Ethernet Controller
      ];
      kernelModules = [ ];
    };

    # AMD GPU support
    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
      "pcie_aspm=off"
    ];
    kernelModules = [
      "amdgpu"
      "ip_tables"
      "iptable_filter"
      "iptable_mangle"
      "iptable_nat"
      "kvm-amd"
    ];
    extraModulePackages = [ ];
    extraModprobeConfig = ''
      # Disable Energy-Efficient Ethernet (EEE)driver
      # EEE can cause link flapping with certain switches routers 
      options igc EEE=0
    '';

    # Enable ZFS and BTRFS
    supportedFilesystems = [
      "zfs"
      "btrfs"
    ];
    zfs.forceImportRoot = true; # Required when forceImportAll is true
    zfs.forceImportAll = true; # Import all pools at boot
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

  # BTRFS services
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  fileSystems = {
    # BTRFS root with subvolumes
    "/" = {
      device = "/dev/disk/by-uuid/57e0ec68-4239-435b-8d91-081ba33661eb";
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
      device = "/dev/disk/by-uuid/57e0ec68-4239-435b-8d91-081ba33661eb";
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
      device = "/dev/disk/by-uuid/57e0ec68-4239-435b-8d91-081ba33661eb";
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
      device = "/dev/disk/by-uuid/57e0ec68-4239-435b-8d91-081ba33661eb";
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
      device = "/dev/disk/by-uuid/57e0ec68-4239-435b-8d91-081ba33661eb";
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
      device = "/dev/disk/by-uuid/57e0ec68-4239-435b-8d91-081ba33661eb";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
        "ssd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/5570-1CCB";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    # ZFS pool for docker and container storage (2x NVMe in mirror)
    # Dataset has canmount=noauto set, so systemd handles mounting
    # This avoids conflicts with ZFS auto-mounting that cause emergency mode
    "/store" = {
      device = "store/store";
      fsType = "zfs";
      options = [
        "zfsutil"
        "x-systemd.requires=zfs-import-store.service"
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

  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;

  # Required for ZFS
  networking.hostId = "678455ab"; # Generate with: head -c 8 /etc/machine-id
}
