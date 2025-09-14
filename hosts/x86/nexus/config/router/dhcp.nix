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

      server = [
        "127.0.0.1#5453" # AdGuard on port 5453 - ONLY DNS server
        "/ryot.foo/127.0.0.1#5453" # Domain-specific forwarding
      ];

      # Listen on all internal interfaces + localhost
      interface = [
        "lo" # Loopback for nexus itself
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
        # Router/gateway accessible from each network with correct gateway IP
        "/router.ryot.local/104.40.4.1" # RUNE network
        "/router.ryot.local/104.40.3.1" # ZEBES network
        "/router.ryot.local/104.40.2.1" # NIMBUS network
        "/router.ryot.local/13.19.89.1" # HAZE network
        "/router/104.40.4.1" # RUNE network (short form)
        "/router/104.40.3.1" # ZEBES network (short form)
        "/router/104.40.2.1" # NIMBUS network (short form)
        "/router/13.19.89.1" # HAZE network (short form)

        # AdGuard web UI accessible from each network
        "/adguard.ryot.foo/104.40.4.1" # RUNE network
        "/adguard.ryot.foo/104.40.3.1" # ZEBES network
        "/adguard.ryot.foo/104.40.2.1" # NIMBUS network
        "/adguard.ryot.foo/13.19.89.1" # HAZE network

        # Pangolin services (all *.ryot.foo) route to gerbil reverse proxy via host IPs
        "/pangolin.ryot.foo/104.40.4.1" # RUNE network - Pangolin web UI via gerbil
        "/pangolin.ryot.foo/104.40.3.1" # ZEBES network - Pangolin web UI via gerbil  
        "/pangolin.ryot.foo/104.40.2.1" # NIMBUS network - Pangolin web UI via gerbil
        "/pangolin.ryot.foo/13.19.89.1" # HAZE network - Pangolin web UI via gerbil
        "/.ryot.foo/104.40.4.1" # RUNE network - All *.ryot.foo domains via gerbil
        "/.ryot.foo/104.40.3.1" # ZEBES network - All *.ryot.foo domains via gerbil
        "/.ryot.foo/104.40.2.1" # NIMBUS network - All *.ryot.foo domains via gerbil
        "/.ryot.foo/13.19.89.1" # HAZE network - All *.ryot.foo domains via gerbil

        # Direct service access (internal use)
        "/gerbil.ryot.local/104.40.1.11" # Direct gerbil access
        "/pangolin.ryot.local/104.40.1.10" # Direct pangolin access

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
