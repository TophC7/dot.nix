{
  pkgs,
  inputs,
  config,
  lib,
  modulesPath,
  host,
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

    # Enable BTRFS
    supportedFilesystems = [
      "btrfs"
    ];

    # Allow running ARM binaries on x86_64; for Cross Compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # For less permission issues with SSHFS
  programs.fuse.userAllowOther = true;

  # BTRFS services
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [
      "/"
      "/steam"
    ];
  };

  # Ensure /steam directory exists
  systemd.tmpfiles.rules = [
    "d /steam 0755 ${host.user.name} ryot - -"
  ];

  fileSystems = {
    # BTRFS root with subvolumes
    "/" = {
      device = "/dev/disk/by-uuid/28d649f5-d3fd-4f60-9a03-efc3680395d0";
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
      device = "/dev/disk/by-uuid/28d649f5-d3fd-4f60-9a03-efc3680395d0";
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
      device = "/dev/disk/by-uuid/28d649f5-d3fd-4f60-9a03-efc3680395d0";
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
      device = "/dev/disk/by-uuid/28d649f5-d3fd-4f60-9a03-efc3680395d0";
      fsType = "btrfs";
      options = [
        "subvol=@log"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/.snapshots" = {
      device = "/dev/disk/by-uuid/28d649f5-d3fd-4f60-9a03-efc3680395d0";
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
      device = "/dev/disk/by-uuid/28d649f5-d3fd-4f60-9a03-efc3680395d0";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
        "ssd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/0606-264A";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    # Steam drive (old NixOS SSD repurposed)
    "/steam" = {
      device = "/dev/disk/by-uuid/3786b62a-66db-4637-a6d1-a29ca1cc8501";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
        "nofail"
      ];
    };
  };

  # Swapfile on BTRFS subvolume
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
    }
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
# nix eval '<HOME>/git/Nix/dot.nix#nixosConfigurations.rune.config.boot.kernelPackages.kernel.outPath'
# curl -L 'https://chaotic-nyx.cachix.org/{{HASH}}.narinfo'
# sudo nixos-rebuild switch --flake ./git/Nix/dot.nix/. --option 'extra-substituters' 'https://chaotic-nyx.cachix.org/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
