{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Disable NetworkManager and default DHCP
  networking = {
    networkmanager.enable = lib.mkForce false;
    useDHCP = false;

    # Set hostname
    hostName = config.hostSpec.hostName;

    # Enable IPv6
    enableIPv6 = true;

    # Define network interfaces
    interfaces = {
      ## WAN ##
      enp1s0 = {
        useDHCP = true;
      };

      ## RUNE ## (104.40.4.0/24)
      enp2s0 = {
        ipv4.addresses = [
          {
            address = "104.40.4.1";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = "fd30:3484:4f32:4::1";
            prefixLength = 64;
          }
        ];
      };

      ## ZEBES ## (104.40.3.0/24)
      enp3s0 = {
        ipv4.addresses = [
          {
            address = "104.40.3.1";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = "fd30:3484:4f32:3::1";
            prefixLength = 64;
          }
        ];
      };

      ## NIMBUS ## (104.40.2.0/24)
      enp4s0 = {
        ipv4.addresses = [
          {
            address = "104.40.2.1";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = "fd30:3484:4f32:2::1";
            prefixLength = 64;
          }
        ];
      };

      ## HAZE ## (13.19.89.0/24) - USB NIC
      enp0s13f0u1 = {
        ipv4.addresses = [
          {
            address = "13.19.89.1";
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = "fd30:3484:4f32:89::1";
            prefixLength = 64;
          }
        ];
      };
    };

    # DNS servers for the router itself
    # Will use local AdGuard once it's running
    nameservers = [
      "127.0.0.1"
      "::1"
      "1.1.1.1" # Fallback
      "1.0.0.1" # Fallback
    ];

    # Search domains
    search = [ "ryot.local" ];

    # Enable DHCP client for WAN interface (override global setting)
    dhcpcd.enable = lib.mkForce true;
  };

  # Enable nftables (replaces iptables)
  networking.nftables.enable = true;

  # Additional network tools
  environment.systemPackages = with pkgs; [
    bridge-utils
    dnslookup
    dnsmasq
    dnsutils
    ethtool
    inetutils
    iperf3
    mtr
    nmap
    speedtest-go
    tcpdump
    traceroute
    wireguard-tools
    host
  ];
}
