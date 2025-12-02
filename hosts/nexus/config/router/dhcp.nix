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
        "lo" # Loopback
        "enp2s0" # RUNE
        "enp3s0" # ZEBES
        "enp4s0" # NIMBUS
        "enp0s13f0u1" # HAZE (USB NIC)
        "wg-vpn" # WireGuard VPN interface
      ];

      # Bind to interfaces only (security)
      bind-interfaces = true;

      # Also listen on VPN subnet
      listen-address = [
        "127.0.0.1" # Loopback
        "10.10.0.1" # VPN interface IP
      ];

      # DHCP ranges for each network
      dhcp-range = [
        # RUNE network
        "10.4.4.100,10.4.4.250,12h"
        # ZEBES network
        "10.3.3.100,10.3.3.250,12h"
        # NIMBUS network
        "10.2.2.100,10.2.2.250,12h"
        # HAZE network
        "10.19.89.100,10.19.89.250,12h"
      ];

      # Static DHCP reservations
      dhcp-host = [
        # RUNE network hosts
        "10:FF:E0:2E:AD:64,10.4.4.4,rune"

        # ZEBES network hosts
        "A8:A1:59:E1:31:79,10.3.3.3,zebes"

        # NIMBUS network hosts
        "34:5A:60:58:1C:60,10.2.2.2,nimbus"
        "C8:53:09:F9:63:7F,10.2.2.4,norion"

        # HAZE network hosts
        "74:56:3C:E7:F8:CD,10.19.89.13,haze"
      ];

      # Custom DNS entries
      address = [
        # Router/gateway accessible from each network with correct gateway IP
        "/router.ryot.local/10.4.4.1" # RUNE
        "/router.ryot.local/10.3.3.1" # ZEBES
        "/router.ryot.local/10.2.2.1" # NIMBUS
        "/router.ryot.local/10.19.89.1" # HAZE

        # AdGuard web UI
        "/adguard.ryot.foo/10.4.4.1" # RUNE
        "/adguard.ryot.foo/10.3.3.1" # ZEBES
        "/adguard.ryot.foo/10.2.2.1" # NIMBUS
        "/adguard.ryot.foo/10.19.89.1" # HAZE

        # Pangolin web UI
        "/pangolin.ryot.foo/10.4.4.1" # RUNE
        "/pangolin.ryot.foo/10.3.3.1" # ZEBES
        "/pangolin.ryot.foo/10.2.2.1" # NIMBUS
        "/pangolin.ryot.foo/10.19.89.1" # HAZE

        # All *.ryot.foo domains via gerbil
        "/.ryot.foo/10.4.4.1" # RUNE
        "/.ryot.foo/10.3.3.1" # ZEBES
        "/.ryot.foo/10.2.2.1" # NIMBUS
        "/.ryot.foo/10.19.89.1" # HAZE

        # Direct local host access
        "/gerbil.ryot.local/10.1.1.11"
        "/pangolin.ryot.local/10.1.1.10"

        # Static host entries (for hosts not using DHCP)
        "/nimbus/10.2.2.2" # Nimbus uses static IP
        "/nimbus.ryot.local/10.2.2.2" # Alternative FQDN

        # Minecraft server (zebes)
        "/mc.goldenlemon.cc/10.3.3.3"
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
