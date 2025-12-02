# Extended host specification for dot.nix
# Extends mix.nix's base hostSpec with storage, networking, and VPN options
#
# This is a mix.nix extension - uses lib.hosts.mkHostSpec to add
# custom options while preserving all base hostSpec functionality.
#
# Usage:
#   # In host definitions:
#   mix.hosts.desktop = {
#     user = "toph";
#     ip = "192.168.1.10";
#     mounts.fast = true;
#     mounts.tank = true;
#     vpn = {
#       publicKey = "abc123...";
#       address = "10.10.0.2/32";
#     };
#   };
#
# For modules usage see: modules/hosts/core/mounts.nix
#
{ lib }:
let
  inherit (lib) mkOption;
  t = lib.types;

  # ─────────────────────────────────────────────────────────────
  # MOUNT POINTS - Storage pool configuration
  # ─────────────────────────────────────────────────────────────

  mountsType = t.submodule {
    options = {
      fast = mkOption {
        type = t.bool;
        description = "Mount the /fast storage pool (NVMe, high-speed scratch)";
        default = false;
      };

      tank = mkOption {
        type = t.bool;
        description = "Mount the /tank storage pool (ZFS, bulk storage)";
        default = false;
      };

      store = mkOption {
        type = t.bool;
        description = "Mount the /store storage pool (application data)";
        default = false;
      };

      hold = mkOption {
        type = t.bool;
        description = "Mount the /hold storage pool (long-term archives)";
        default = false;
      };

      repo = mkOption {
        type = t.bool;
        description = "Mount the /repo storage pool (git repos, Nix config)";
        # Almost all hosts need /repo - it's where the flake lives
        default = true;
      };
    };
  };

  # ─────────────────────────────────────────────────────────────
  # VPN - WireGuard configuration (non-sensitive parts)
  # ─────────────────────────────────────────────────────────────

  vpnType = t.submodule {
    options = {
      publicKey = mkOption {
        type = t.str;
        description = "WireGuard public key for this host";
        example = "xTIBA5rboUvnH4htodjb60Y7YAf21w7HkAPtUYZV8yY=";
      };

      address = mkOption {
        type = t.str;
        description = "IP address for WireGuard interface (with CIDR notation)";
        example = "10.10.0.2/32";
      };

      endpoint = mkOption {
        type = t.nullOr t.str;
        description = "WireGuard endpoint (for clients connecting to a server)";
        default = null;
        example = "vpn.example.com:51820";
      };

      persistentKeepalive = mkOption {
        type = t.nullOr t.int;
        description = "Persistent keepalive interval in seconds (for NAT traversal)";
        default = null;
        example = 25;
      };

      allowedIPs = mkOption {
        type = t.listOf t.str;
        description = "List of allowed IP ranges for this peer";
        default = [ ];
        example = [
          "10.10.0.0/24"
          "192.168.1.0/24"
        ];
      };
    };
  };

in
lib.hosts.mkHostSpec {
  # ─────────────────────────────────────────────────────────────
  # EXTENDED OPTIONS
  # ─────────────────────────────────────────────────────────────

  options.mounts = mkOption {
    type = mountsType;
    description = "Storage mount points for this host";
    default = { };
  };

  options.ip = mkOption {
    type = t.nullOr t.str;
    description = "Static IP address for this host (LAN address)";
    default = null;
    example = "192.168.1.10";
  };

  options.vpn = mkOption {
    type = t.nullOr vpnType;
    description = "WireGuard VPN configuration (non-sensitive parts only)";
    default = null;
  };
}
