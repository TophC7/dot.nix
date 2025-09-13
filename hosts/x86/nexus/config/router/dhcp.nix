{
  config,
  lib,
  pkgs,
  ...
}:

{
  # DNSMasq for DHCP and DNS
  services.dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;

    settings = {
      # General settings
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;

      # Local domain
      local = "/ryot.local/";
      domain = "ryot.local";
      expand-hosts = true;

      # DNS settings
      cache-size = 1000;

      # Forward DNS queries to AdGuard
      server = [
        "127.0.0.1#5453" # AdGuard on port 5453
        "/ryot.foo/127.0.0.1#5453" # Domain-specific forwarding
        "1.1.1.1"
        "1.0.0.1"
      ];

      # Listen on all internal interfaces
      interface = [
        "enp2s0" # RUNE
        "enp3s0" # ZEBES
        "enp4s0" # NIMBUS
        "enp0s13f0u1" # HAZE (USB NIC)
      ];

      # Bind to interfaces only (security)
      bind-interfaces = true;

      # DHCP ranges for each network
      dhcp-range = [
        # RUNE network
        "104.40.4.100,104.40.4.250,12h"
        # ZEBES network
        "104.40.3.100,104.40.3.250,12h"
        # NIMBUS network
        "104.40.2.100,104.40.2.250,12h"
        # HAZE network
        "13.19.89.100,13.19.89.250,12h"
      ];

      # Static DHCP reservations
      dhcp-host = [
        # RUNE network hosts
        "10:FF:E0:2E:AD:64,104.40.4.7,rune"

        # ZEBES network hosts
        "A8:A1:59:E1:31:79,104.40.3.3,zebes"

        # HAZE network hosts
        "74:56:3C:E7:F8:CD,13.19.89.13,haze"

        # NIMBUS network hosts
        "C8:53:09:F9:63:7F,104.40.2.7,norion"
        "34:5A:60:58:1C:60,104.40.2.24,nimbus"
      ];

      # Custom DNS entries
      address = [
        # Nexus router accessible from each network as Pixel
        "/pixel.ryot.local/104.40.4.1" # RUNE network
        "/pixel.ryot.local/104.40.3.1" # ZEBES network
        "/pixel.ryot.local/104.40.2.1" # NIMBUS network
        "/pixel.ryot.local/13.19.89.1" # HAZE network

        # DNS accessible from each network
        "/adguard.ryot.foo/104.40.4.1" # RUNE network
        "/adguard.ryot.foo/104.40.3.1" # ZEBES network
        "/adguard.ryot.foo/104.40.2.1" # NIMBUS network
        "/adguard.ryot.foo/13.19.89.1" # HAZE network

        "/mc.goldenlemon.cc/104.40.3.3"
      ];

      # SRV records
      srv-host = [
        # Minecraft server
        "_minecraft._tcp.mc,mc.goldenlemon.cc,25565,0,0"
      ];

      # Disable DNSSEC validation (causes SERVFAIL issues)
      # Let AdGuard handle DNS security instead
      dnssec = false;

      # Logging
      log-queries = false; # Set to true for debugging
      log-dhcp = false; # Set to true for debugging
    };
  };

  # Ensure dnsmasq starts after network is ready
  systemd.services.dnsmasq = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # Restart on failure
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
