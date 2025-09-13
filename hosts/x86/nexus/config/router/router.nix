{
  config,
  lib,
  pkgs,
  ...
}:

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
    ];
    forwardPorts = [
      # Example port forwards (uncomment and modify as needed)
      # { sourcePort = 80; destination = "104.40.3.34:80"; proto = "tcp"; }
    ];
  };

  # Firewall configuration using nftables
  networking.firewall = {
    enable = true;

    # Allow ping
    allowPing = true;

    # Log rejected connections
    logRefusedConnections = false;
    logRefusedPackets = false;

    # Trusted interfaces (full access)
    trustedInterfaces = [
      "enp2s0" # RUNE network is fully trusted
    ];

    # Define per-interface rules
    interfaces = {
      # WAN interface - restrictive
      enp1s0 = {
        allowedTCPPorts = [ ]; # No incoming connections from WAN
        allowedUDPPorts = [ ];
      };

      # RUNE interface - main LAN
      enp2s0 = {
        allowedTCPPorts = [
          22 # SSH
          53 # DNS
          80 # HTTP
          443 # HTTPS
        ];
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
          68 # DHCP
        ];
      };

      # ZEBES interface - services network
      enp3s0 = {
        allowedTCPPorts = [
          22 # SSH
          53 # DNS
          80 # HTTP
          443 # HTTPS
          3000 # AdGuard admin
        ];
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
          68 # DHCP
        ];
      };

      # NIMBUS interface
      enp4s0 = {
        allowedTCPPorts = [
          22 # SSH
          53 # DNS
          80 # HTTP
          443 # HTTPS
        ];
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
          68 # DHCP
        ];
      };

      # HAZE interface - isolated network (USB NIC)
      enp0s13f0u1 = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
          68 # DHCP
        ];
      };
    };

  };

  # Custom nftables rules for zone-based forwarding
  networking.nftables = {
    enable = true;
    tables = {
      router_zones = {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority 0; policy accept;
            
            # Allow established connections
            ct state established,related accept
            
            # RUNE (enp2s0) can reach everywhere
            iifname "enp2s0" accept
            
            # ZEBES (enp3s0) rules
            iifname "enp3s0" oifname "enp1s0" accept   # ZEBES -> WAN
            iifname "enp3s0" oifname "enp2s0" accept   # ZEBES -> RUNE
            iifname "enp3s0" oifname "enp4s0" accept   # ZEBES -> NIMBUS
            iifname "enp3s0" oifname "enp0s13f0u1" accept  # ZEBES -> HAZE
            
            # NIMBUS (enp4s0) rules
            iifname "enp4s0" oifname "enp1s0" accept   # NIMBUS -> WAN
            iifname "enp4s0" oifname "enp2s0" accept   # NIMBUS -> RUNE
            iifname "enp4s0" oifname "enp3s0" accept   # NIMBUS -> ZEBES
            iifname "enp4s0" oifname "enp0s13f0u1" accept  # NIMBUS -> HAZE
            
            # HAZE (enp0s13f0u1) rules - isolated (USB NIC)
            iifname "enp0s13f0u1" oifname "enp1s0" accept   # HAZE -> WAN
            iifname "enp0s13f0u1" oifname "enp3s0" accept   # HAZE -> ZEBES
            iifname "enp0s13f0u1" oifname "enp4s0" accept   # HAZE -> NIMBUS
            iifname "enp0s13f0u1" oifname "enp2s0" drop     # HAZE -X-> RUNE (blocked)
            
            # Allow return traffic from all zones to RUNE (except HAZE which is blocked)
            iifname "enp1s0" oifname "enp2s0" ct state established,related accept
            iifname "enp3s0" oifname "enp2s0" ct state established,related accept
            iifname "enp4s0" oifname "enp2s0" ct state established,related accept
            
            # MSS clamping for PPPoE/VPN compatibility
            tcp flags syn tcp option maxseg size set rt mtu
          }
        '';
      };
    };
  };

  # Note: autoLoadConntrackHelpers removed in kernel 6.0+
  # Use manual nftables rules instead if needed
}
