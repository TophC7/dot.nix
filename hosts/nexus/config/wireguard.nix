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
  # - Not this host (nexus - the server)
  # - Has a /32 address (clients have /32, server has /24)
  vpnClients = lib.filterAttrs (
    name: spec:
    name != host.hostName && spec.vpn or null != null && lib.hasSuffix "/32" (spec.vpn.address or "")
  ) hosts;

  clientPublicKey = name: lib.attrByPath [ "service" "wg-${name}" "publicKey" ] null secrets;
  missingPublicKeys = lib.filter (name: clientPublicKey name == null) (lib.attrNames vpnClients);

  # Build peer config from host spec and key stored in secrets
  mkPeer =
    name: spec:
    let
      publicKey = clientPublicKey name;
    in
    {
      publicKey = if publicKey == null then "" else publicKey;
      allowedIPs = [ spec.vpn.address ];
      persistentKeepalive = spec.vpn.persistentKeepalive or 25;
    };
in
{
  assertions = [
    {
      assertion = missingPublicKeys == [ ];
      message = "VPN clients missing WireGuard public keys in secrets: ${lib.concatStringsSep ", " missingPublicKeys}";
    }
  ];

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
      # Allow rathole container (on pangolin bridge) to reach WireGuard
      # Docker NAT rules intercept local-destined traffic before the normal
      # firewall rules apply, so we need an explicit rule for br-pangolin
      extraInputRules = ''
        iifname "br-pangolin" udp dport ${toString vpnPort} accept
      '';
    };
  };
}
