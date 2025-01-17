{
  config,
  lib,
  pkgs,
  modulesPath,
  admin,
  ...
}:
{

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Bootloader
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
      verbose = false;
    };

    extraModulePackages = [ ];
    kernelParams = [
      "quiet"
      "splash"
      "vga=current"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    kernelModules = [
      "kvm-amd"
      "i2c-dev"
    ];

    consoleLogLevel = 0;
  };
  # Configurations for ddcutil
  hardware.i2c.enable = true;
  services.udev = {
    enable = true;
    extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';

    # Extra Hardware Database (Hwdb) entries
    # FIXME: not doing anything rn, mouse wheel still the same
    extraHwdb = ''
      # Logitech USB Receiver (for G903)
      mouse:usb:v046dpC539:name:Logitech USB Receiver:*
       MOUSE_WHEEL_CLICK_ANGLE=40
       MOUSE_WHEEL_CLICK_COUNT=1
    '';

  };

  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  # File system configurations
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/28a9ac4d-1e87-4731-9c06-916711d83cb2";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/B182-E50E";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/pool" = {
      device = "${admin}@104.40.4.24:/pool";
      fsType = "sshfs";
      options = [
        "defaults"
        "reconnect"
        "_netdev"
        "allow_other"
        "identityfile=/home/${admin}/.ssh/pve"
      ];
    };

    "/home/${admin}/git" = {
      fsType = "none";
      device = "/pool/git";
      options = [
        "bind"
        "nofail"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/81b6fa27-af94-41d4-9070-8754087a4c26"; } ];

  # Time and networking configurations
  time.hardwareClockInLocalTime = true; # Fixes windows dual-boot time issues
  networking.useDHCP = lib.mkDefault true;

  # Hardware configurations
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
