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
  ];

  ## Boot ##
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # When using plymouth, initrd can expand by a lot each time, so limit how many we keep around
        configurationLimit = lib.mkDefault 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Use custom CachyOS kernel with ThinLTO, x86_64-v3, and BBR3
    kernelPackages = pkgs.linuxPackages-ryot;

    initrd = {
      systemd.enable = true;
      verbose = false;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];

      # LUKS encryption - unlocks the encrypted root partition
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-uuid/cb373530-da5e-4960-86a7-137b139f08a1";
        allowDiscards = true; # Enable TRIM for SSD performance
        bypassWorkqueues = true; # Better SSD performance
      };
    };

    # Workaround for boot issues
    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
    ];
    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];
    extraModulePackages = [ ];

    # Enable BTRFS support
    supportedFilesystems = [ "btrfs" ];

    # Allow running ARM binaries on x86_64; for Cross Compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # BTRFS maintenance - monthly scrub to detect and fix errors
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/349d3431-5c91-41e6-beca-69e774cd627b";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/349d3431-5c91-41e6-beca-69e774cd627b";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/349d3431-5c91-41e6-beca-69e774cd627b";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/var/log" = {
      device = "/dev/disk/by-uuid/349d3431-5c91-41e6-beca-69e774cd627b";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
      neededForBoot = true; # Ensure logs are available early
    };

    "/.snapshots" = {
      device = "/dev/disk/by-uuid/349d3431-5c91-41e6-beca-69e774cd627b";
      fsType = "btrfs";
      options = [
        "subvol=@snapshots"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/swap" = {
      device = "/dev/disk/by-uuid/349d3431-5c91-41e6-beca-69e774cd627b";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
        "ssd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/1E94-6484";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  # 64GB swapfile for hibernation support
  swapDevices = [ { device = "/swap/swapfile"; } ];

  time.hardwareClockInLocalTime = true; # Fixes windows dual-boot time issues
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;
}
