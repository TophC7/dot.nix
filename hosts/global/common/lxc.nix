{
  modulesPath,
  lib,
  config,
  ...
}:
{
  imports = [
    # Include the default lxc/lxd configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # Treats the system as a container.
  boot = {
    isContainer = true;
  };

  console.enable = true;

  nix.settings = {
    sandbox = false;
  };

  systemd = {
    mounts = [
      {
        enable = false;
        where = "/sys/kernel/debug";
      }
    ];

    # By default only starts getty on tty0 but first on LXC is tty1
    services."autovt@".unitConfig.ConditionPathExists = [
      ""
      "/dev/%I"
    ];

    # These are disabled by `console.enable` but console via tty is the default in Proxmox
    services."getty@tty1".enable = lib.mkForce true;
    services."autovt@".enable = lib.mkForce true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Suppress systemd units that don't work because of LXC.
  # https://blog.xirion.net/posts/nixos-proxmox-lxc/#configurationnix-tweak
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
}
