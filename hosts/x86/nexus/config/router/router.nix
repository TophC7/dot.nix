{
  config,
  lib,
  pkgs,
  ...
}:
let
  network = config.secretsSpec.network.nexus;
in
{
  networking = {
    nat = {
      # Enable NAT for WAN interface
      enable = true;
      externalInterface = "enp1s0"; # WAN
      internalInterfaces = [
        "enp2s0" # RUNE
        "enp3s0" # ZEBES
        "enp4s0" # NIMBUS
        "enp0s13f0u1" # HAZE (USB NIC)
        "wg-vpn" # WireGuard VPN interface
        "br-+" # All Docker bridge networks (br-*)
      ];
      forwardPorts = [
        # Example port forwards (uncomment and modify as needed)
        # { sourcePort = 80; destination = "104.40.3.34:80"; proto = "tcp"; }
      ];
    };

    firewall = {
      # Simple firewall - block WAN, allow specific ports for nexus services
      enable = true;
      interfaces.enp1s0 = {
        allowedTCPPorts = [ ]; # Nothing from WAN
        allowedUDPPorts = [ ];
      };

      # Apply nexus port restrictions from secrets.nix
      allowedTCPPorts = network.firewall.allowedTCPPorts;
      allowedUDPPorts = network.firewall.allowedUDPPorts;
    };
  };
}
