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

    # Allow WireGuard port (will be accessed through Pangolin)
    firewall.interfaces."lo".allowedUDPPorts = [ vpnPort ];

    # Trust the VPN interface completely - allow all traffic
    firewall.trustedInterfaces = [ vpnInterface ];

    # Note: With trustedInterfaces, we don't need specific port allowances
    # The interface is completely trusted for INPUT, OUTPUT, and FORWARD
  };
}
