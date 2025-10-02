{
  config,
  pkgs,
  lib,
  ...
}:
let
  # VPN Configuration
  vpnPort = 51821; # Standard WireGuard port (no conflict, OLM connects to caenus)
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
      privateKey = wgServer.privateKey; # Can use directly!

      peers = lib.mapAttrsToList (hostname: hostConfig: {
        # Use the public key from secrets
        publicKey = hostConfig.wg.publicKey;
        allowedIPs = [ hostConfig.wg.address ];
        persistentKeepalive = 25;
      }) wgClients;
    };

    # Add wg-vpn to NAT internal interfaces
    nat.internalInterfaces = lib.mkAfter [ vpnInterface ];

    # Allow WireGuard port (will be accessed through Pangolin)
    firewall.interfaces."lo".allowedUDPPorts = [ vpnPort ];
  };
}
