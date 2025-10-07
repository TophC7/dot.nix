{
  config,
  pkgs,
  lib,
  host,
  secrets,
  ...
}:
let
  # VPN Configuration
  vpnPort = 51821; # Non-Standard WireGuard port To avoid conflicts with OLM
  vpnInterface = "wg-vpn";

  # Get WireGuard configs
  wgServer = host.network.wg;
  # Get the actual private key from secrets
  wgPrivateKey = secrets.service."wg-nexus".privateKey or "";

  # Get all host configs to find VPN clients
  allHosts = lib.custom.getAllHostConfigs pkgs;

  # Filter hosts that have VPN enabled (have wg config with endpoint)
  wgClients = lib.filterAttrs (
    name: hostConfig:
    name != "nexus"
    && hostConfig.network.wg or null != null
    && hostConfig.network.wg.endpoint or null != null
  ) allHosts;
in
{
  # Networking configuration
  networking = {
    # WireGuard interface
    wireguard.interfaces.${vpnInterface} = {
      ips = [ wgServer.address ];
      listenPort = vpnPort;
      privateKey = wgPrivateKey;

      peers = lib.mapAttrsToList (hostname: hostConfig: {
        # Get the actual public key from secrets
        publicKey = secrets.service."wg-${hostname}".publicKey or "INVALID";
        allowedIPs = [ hostConfig.network.wg.address ];
        persistentKeepalive = hostConfig.network.wg.persistentKeepalive or 25;
      }) wgClients;
    };

    # Note: wg-vpn is added to NAT internal interfaces in router.nix

    firewall = {
      # Allow WireGuard port on all interfaces (accessed through Cloudflare tunnel)
      allowedUDPPorts = [ vpnPort ];
      # FIXME: For now Trust the VPN interface completely - allow all traffic
      trustedInterfaces = [ vpnInterface ];
    };
  };
}
