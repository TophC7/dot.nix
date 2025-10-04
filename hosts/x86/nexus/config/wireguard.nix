{
  config,
  pkgs,
  lib,
  ...
}:
let
  # VPN Configuration
  vpnPort = 51821; # Non-Standard WireGuard port To avoid conflicts with OLM
  vpnInterface = "wg-vpn";

  # Get WireGuard configs from secrets
  wgServer = config.secretsSpec.network.nexus.wg;
  wgClients = lib.filterAttrs (
    name: host: host.wg or null != null && name != "nexus"
  ) config.secretsSpec.network;
in
{
  # Networking configuration
  networking = {
    # WireGuard interface
    wireguard.interfaces.${vpnInterface} = {
      ips = [ wgServer.address ];
      listenPort = vpnPort;
      privateKey = wgServer.privateKey;

      peers = lib.mapAttrsToList (hostname: hostConfig: {
        # Use the public key from secrets
        publicKey = hostConfig.wg.publicKey;
        allowedIPs = [ hostConfig.wg.address ];
        persistentKeepalive = 25;
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
