{
  config,
  lib,
  pkgs,
  ...
}:
let
  firewall = config.secretsSpec.firewall.nexus;
in
{
  # Enable NAT for WAN interface
  networking.nat = {
    enable = true;
    externalInterface = "enp1s0"; # WAN
    internalInterfaces = [
      "enp2s0" # RUNE
      "enp3s0" # ZEBES
      "enp4s0" # NIMBUS
      "enp0s13f0u1" # HAZE (USB NIC)
      "br-+" # All Docker bridge networks (br-*)
    ];
    forwardPorts = [
      # Example port forwards (uncomment and modify as needed)
      # { sourcePort = 80; destination = "104.40.3.34:80"; proto = "tcp"; }
    ];
  };

  # Simple firewall - block WAN, allow specific ports for nexus services
  networking.firewall = {
    enable = true;

    # Block ALL incoming connections from WAN
    interfaces.enp1s0 = {
      allowedTCPPorts = [ ]; # Nothing from WAN
      allowedUDPPorts = [ ];
    };

    # Apply nexus port restrictions from secrets.nix
    allowedTCPPorts = firewall.allowedTCPPorts;
    allowedUDPPorts = firewall.allowedUDPPorts;
  };

}
