{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = lib.flatten [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
      "r8169" # Realtek network cards
      "igb" # Intel network cards
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    # Enable IP forwarding for router functionality
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
    };

    # Use systemd-boot for UEFI systems
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # BTRFS support
    supportedFilesystems = [ "btrfs" ];
    initrd.supportedFilesystems = [ "btrfs" ];
  };

  # BTRFS services
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # BTRFS utilities
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize # Check compression ratio
    btrbk # Backup tool for BTRFS
  ];

  # Filesystem configuration with BTRFS subvolumes
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
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
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
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
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
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
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
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
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
      fsType = "btrfs";
      options = [
        "subvol=@snapshots"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/var/lib/docker" = {
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
      fsType = "btrfs";
      options = [
        "subvol=@docker"
        "compress=zstd:1"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };

    "/swap" = {
      device = "/dev/disk/by-uuid/140e1f6e-97bd-4dff-af0c-4779e28aa980";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
        "ssd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/29D4-E545";
      fsType = "vfat";
    };
  };

  # Swap file on BTRFS
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 8192; # 8GB swap
    }
  ];

  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /var/lib/docker 0755 root root -"
  ];

  # BTRFS snapshot before system updates
  systemd.services.btrfs-snapshot-before-update = {
    description = "Create BTRFS snapshot before system update";
    path = [ pkgs.btrfs-progs ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'btrfs subvolume snapshot -r / /.snapshots/pre-update-$(date +%Y%m%d-%H%M%S)'";
    };
  };

  # Network configuration will be in networking.nix
  networking.useDHCP = false;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
