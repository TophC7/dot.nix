{
  services.dnsmasq = {
    enable = true;
    settings = {
      # Listen on eth0 for external clients and lo for local host
      interface = [
        "eth0"
        "lo"
      ];

      no-hosts = true;
      no-resolv = true;

      server = [
        "104.40.3.1" # Query openWRT first
        "1.1.1.1" # Redundancy
        "1.0.0.1"
        "8.8.8.8"
      ];

      # INFO: Why this setup for services?
      # - OpenWRT forwards every *ryot.foo and *toph.cc query to this DNS server
      # - dnsmasq hands out fixed IPs for those subdomains.
      # - Each target host runs Caddy to serve its site.
      # No Docker labels, no discovery magic—just reliable routing clearly documented with Nix.
      # Its not automated but this is a homelab... ill survive

      address = [
        ## CLOUD ##
        "/drive.ryot.foo/104.40.3.24"

        ## PROXY ##
        "/cloudflared.ryot.foo/104.40.3.34"
        "/ochre.ryot.foo/104.40.3.34"
        "/pve.ryot.foo/104.40.3.34"
        "/wrt.ryot.foo/104.40.3.34"

        ## KOMO ##
        "/auth.ryot.foo/104.40.3.44"
        "/frp.ryot.foo/104.40.3.44"
        "/git.ryot.foo/104.40.3.44"
        "/grafana.ryot.foo/104.40.3.44"
        "/home.ryot.foo/104.40.3.44"
        "/influx.ryot.foo/104.40.3.44"
        "/komodo.ryot.foo/104.40.3.44"
        "/mail.ryot.foo/104.40.3.44"
        "/map.ryot.foo/104.40.3.44"
        "/outline.ryot.foo/104.40.3.44"
        "/plane.ryot.foo/104.40.3.44"

        "/blog.toph.cc/104.40.3.44"

        ## SOCK ##
        "/upsnap.ryot.foo/104.40.3.54"
        "/sock.ryot.foo/104.40.3.54"
      ];

      cache-size = 1000;

      # Log queries for debugging (optional)'
      # log-queries = true;
    };
  };

  networking = {
    # Open DNS port in firewall
    firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
