{
  lib,
  host,
  hosts,
  secrets,
  ...
}:
let
  # VPN Configuration
  vpnPort = 51821; # Non-standard WireGuard port to avoid conflicts with OLM
  vpnInterface = "wg-vpn";

  # Server config from host spec
  serverAddress = host.vpn.address; # e.g., "10.10.0.1/24"

  # Private key from secrets
  privateKey = secrets.service."wg-nexus".privateKey or "";

  # ── Dynamic VPN Client Discovery ──
  # Filter hosts that are VPN clients:
  # - Not this host (nexus)
  # - Has vpn config
  # - Has endpoint set (clients connect TO a server, servers don't have endpoint)
  vpnClients = lib.filterAttrs (
    name: spec: name != host.hostName && spec.vpn or null != null && spec.vpn.endpoint or null != null
  ) hosts;

  # Build peer config from host spec
  mkPeer = name: spec: {
    publicKey = spec.vpn.publicKey;
    allowedIPs = [ spec.vpn.address ];
    persistentKeepalive = spec.vpn.persistentKeepalive or 25;
  };
in
{
  networking = {
    # WireGuard VPN server interface
    wireguard.interfaces.${vpnInterface} = {
      ips = [ serverAddress ];
      listenPort = vpnPort;
      inherit privateKey;

      # Dynamically generate peers from all VPN-enabled hosts
      peers = lib.mapAttrsToList mkPeer vpnClients;
    };

    # Note: wg-vpn is added to NAT internal interfaces in router.nix

    firewall = {
      # Allow WireGuard port (accessed through Cloudflare tunnel)
      allowedUDPPorts = [ vpnPort ];
      # Trust the VPN interface - allow all traffic from VPN peers
      trustedInterfaces = [ vpnInterface ];
    };
  };
}
