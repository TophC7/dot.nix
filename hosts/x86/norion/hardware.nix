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

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableAllFirmware;

}

# STUFF ABOUT CHAOTIC NIX CACHE
# nix eval 'github:chaotic-cx/nyx/nyxpkgs-unstable#linuxPackages_cachyos.kernel.outPath'
# nix eval 'chaotic#linuxPackages_cachyos.kernel.outPath'
# nix eval '/pool/git/Nix/dot.nix#nixosConfigurations.rune.config.boot.kernelPackages.kernel.outPath'
# curl -L 'https://chaotic-nyx.cachix.org/{{HASH}}.narinfo'
# sudo nixos-rebuild switch --flake ./git/Nix/dot.nix/. --option 'extra-substituters' 'https://chaotic-nyx.cachix.org/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
