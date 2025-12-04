# Dynamic NFS mount configuration based on host specifications
# Reads mount toggles from host.mounts (defined in mix/hostSpec.nix)
#
# Usage:
#   mix.hosts.desktop.mounts = {
#     fast = true;   # Mount /fast from nimbus
#     tank = true;   # Mount /tank from nimbus
#     repo = true;   # Mount /repo from nimbus (default: true)
#   };
#
{
  lib,
  host,
  ...
}:
let
  username = host.user.name;

  # Mount configuration from extended hostSpec
  # Use empty set as default if mounts not specified
  hostMounts = host.mounts or { };

  # Define mount sources
  mountConfigs = {
    fast = {
      server = "nimbus";
      path = "/fast";
    };
    hold = {
      server = "router";
      path = "/hold";
    };
    repo = {
      server = "nimbus";
      path = "/repo";
    };
    store = {
      server = "zebes";
      path = "/store";
    };
    tank = {
      server = "nimbus";
      path = "/tank";
    };
  };

  # Helper function to generate mount configuration
  mkNfsMount = name: cfg: {
    mount = {
      enable = true;
      what = "${cfg.server}:${cfg.path}";
      where = cfg.path;
      type = "nfs";
      options = "nfsvers=4.2,noatime,soft,intr";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig = {
        TimeoutSec = "10";
      };
      mountConfig = {
        TimeoutSec = "10";
      };
    };

    automount = {
      enable = true;
      where = cfg.path;
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
    };

    tmpfile = "d ${cfg.path} 2775 ${username} ryot -";
  };

  # Generate mounts only for enabled mount points
  enabledMounts = lib.filterAttrs (name: _: hostMounts.${name} or false) mountConfigs;

  # Generate all mount configurations
  allMountConfigs = lib.mapAttrs mkNfsMount enabledMounts;

  # Extract specific configuration types
  mounts = lib.mapAttrsToList (_: cfg: cfg.mount) allMountConfigs;
  automounts = lib.mapAttrsToList (_: cfg: cfg.automount) allMountConfigs;
  tmpfiles = lib.mapAttrsToList (_: cfg: cfg.tmpfile) allMountConfigs;

in
{
  # Only configure if there are any mounts enabled
  config = lib.mkIf (enabledMounts != { }) {
    # Create mount point directories
    systemd.tmpfiles.rules = tmpfiles;

    # Configure systemd mounts
    systemd.mounts = mounts;
    systemd.automounts = automounts;

    # Ensure NFS client support
    boot.supportedFilesystems = [ "nfs" ];

    # NFS client configuration
    services.nfs.idmapd.settings = {
      General = {
        Domain = "ryot.local"; # Must match on server and client
        Verbosity = 0;
      };
    };
  };
}
