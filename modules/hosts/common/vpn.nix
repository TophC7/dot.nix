# WireGuard VPN via NetworkManager
#
# Creates a NetworkManager profile for the homelab VPN that can be
# controlled via nm-applet or nmcli instead of systemd commands.
#
# Usage:
#   - GUI: Click nm-applet tray icon → VPN Connections → wg-homelab
#   - CLI: nmcli con up wg-homelab / nmcli con down wg-homelab
#
{
  lib,
  host,
  secrets,
  ...
}:
let
  cfgWg = host.vpn or null;
  # Get the actual nexus public key from secrets
  nexusPublicKey = secrets.service."wg-nexus".publicKey or null;
  # Get private key for this host from secrets
  hostPrivateKey = secrets.service."wg-${host.hostName}".privateKey or "";

  # Allowed IP ranges for the VPN (semicolon-separated for NetworkManager)
  allowedIPs = lib.concatStringsSep ";" [
    "10.10.0.0/24" # VPN subnet (includes DNS at 10.10.0.1)
    "10.1.1.0/24" # Pangolin/LAN network
    "10.2.2.0/24" # NIMBUS network
    "10.3.3.0/24" # ZEBES network
    "10.4.4.0/24" # RUNE network
    "10.19.89.0/24" # HAZE network
  ];
in
{
  config = lib.mkIf (cfgWg != null && cfgWg.endpoint != null) {
    assertions = [
      {
        assertion = nexusPublicKey != null;
        message = "VPN configuration requires nexus host to have a WireGuard public key defined";
      }
    ];

    # Allow WireGuard traffic through reverse path filter
    networking.firewall.checkReversePath = "loose";

    # NetworkManager WireGuard profile
    # Managed via nm-applet GUI or: nmcli con up/down wg-homelab
    networking.networkmanager.ensureProfiles.profiles.wg-homelab = {
      connection = {
        id = "wg-homelab";
        type = "wireguard";
        interface-name = "wg-homelab";
        autoconnect = "false";
      };

      wireguard = {
        private-key = hostPrivateKey;
      };

      # Peer config - section name includes the public key
      "wireguard-peer.${nexusPublicKey}" = {
        endpoint = cfgWg.endpoint;
        persistent-keepalive = "25";
        allowed-ips = allowedIPs;
      };

      ipv4 = {
        method = "manual";
        address1 = cfgWg.address; # e.g., "10.10.0.4/32"
        dns = "10.10.0.1;";
        dns-search = "ryot.local;ryot.foo;";
      };

      ipv6 = {
        method = "disabled";
      };
    };
  };
}
