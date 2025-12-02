{
  lib,
  ...
}:
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
        "wg-+" # WireGuard VPN interface
        "br-+" # All Docker bridge networks (br-*)
      ];
      forwardPorts = [
        # Example port forwards (uncomment and modify as needed)
        # { sourcePort = 80; destination = "10.3.3.34:80"; proto = "tcp"; }
      ];
    };

    firewall = {
      # Simple firewall - block WAN, allow specific ports for nexus services
      enable = true;

      # Block everything from WAN
      interfaces.enp1s0 = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };

      # Service ports are defined in hosts/nexus/default.nix
    };
  };
}
