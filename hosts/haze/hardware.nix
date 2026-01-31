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
        # Configure loader.conf to remember last booted entry
        extraInstallCommands = ''
          ${pkgs.gnused}/bin/sed -i '/^default /d' /boot/loader/loader.conf
          echo "default @saved" >> /boot/loader/loader.conf
        '';
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Use custom CachyOS kernel with ThinLTO, x86_64-v3, and BBR3
    kernelPackages = pkgs.linuxPackages-ryot;

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
    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];
    extraModulePackages = [ ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5615474c-c665-407e-8f60-c221414ae343";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C9F2-4C1F";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/10529583-bde9-4aad-8001-f5954c4a1474"; }
  ];

  time.hardwareClockInLocalTime = true; # Fixes windows dual-boot time issues

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;

}
