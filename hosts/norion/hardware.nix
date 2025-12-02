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
        # When using plymouth, initrd can expand by a lot each time, so limit how many we keep around
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
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
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

    # Allow running ARM binaries on x86_64; for Cross Compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/9c3e9ec0-7f6d-4bda-9506-ef63a6c45644";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/8549-B28F";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/06a1b13c-6855-4e92-9dac-08850bd3b470"; }
  ];

  time.hardwareClockInLocalTime = true; # Fixes windows dual-boot time issues
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;
}
