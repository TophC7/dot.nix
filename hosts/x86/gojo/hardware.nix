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

    # Kernel sysctl parameters
    kernel.sysctl = {
      # Make swap only activate when absolutely necessary (0-200, default is 60)
      "vm.swappiness" = 1;
    };

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

    # Workaround for boot issues
    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
    ];
    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];
    extraModulePackages = [ ];
  };

  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b68db330-60b8-422b-a75c-6e92d0eb6095";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/52FE-E21B";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/a04d4d68-e167-4409-bfb0-7226f2c74b4a"; } ];

  time.hardwareClockInLocalTime = true; # Fixes windows dual-boot time issues
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;

}
