{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Get caenus IP for direct connection (bypasses DNS/Cloudflare)
  caenusIp = config.secretsSpec.network.caenus.ip or null;

  # Check if any WireGuard service is enabled
  wireguardEnabled =
    (config.services.olm.enable or false)
    || (config.networking.wg-quick.interfaces != { })
    || (config.networking.wireguard.interfaces != { });
in
{
  # Essential WireGuard setup when any WireGuard-dependent service is enabled
  config = lib.mkMerge [
    # Base networking configuration
    {
      networking = {
        dhcpcd.enable = false;
        hostName = config.hostSpec.hostName;
        networkmanager.enable = true;
        useDHCP = lib.mkDefault true;
        useHostResolvConf = false;
        usePredictableInterfaceNames = true;
      };
    }

    # WireGuard configuration when needed
    (lib.mkIf wireguardEnabled {
      # Ensure WireGuard kernel module is available
      boot.kernelModules = [ "wireguard" ];

      # Include WireGuard tools in system packages
      environment.systemPackages = with pkgs; [
        wireguard-tools
      ];

      # Direct IP mapping for pangolin.ryot.foo to bypass DNS/Cloudflare
      # Ensures reliable VPN connection even when DNS or Cloudflare is down
      networking.hosts = lib.mkIf (caenusIp != null) {
        "${caenusIp}" = [ "pangolin.ryot.foo" ];
      };

      # Enable IP forwarding if this is a server/router
      # (only for hosts that route traffic between interfaces)
      boot.kernel.sysctl = lib.mkIf (config.hostSpec.isServer or false) {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
    })
  ];
}
