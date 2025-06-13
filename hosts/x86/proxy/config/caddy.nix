{
  services.caddy = {
    enable = true;
    virtualHosts = {
      "adguard.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:3000
        '';
      };

      "cloudflared.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:14333
        '';
      };

      ## openWRT ##

      "wrt.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.3.1 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Port {server_port}
          }
        '';
      };

      ## PROXMOX NODES ##

      "ochre.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy https://104.40.3.2:8006 {
            transport http {
              tls_insecure_skip_verify
              # optional: tls_server_name 104.40.3.2
            }
            # ensure Proxmox sees the right Host
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Port {server_port}
          }
        '';
      };

      "pve.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy https://104.40.3.3:8006 {
            transport http {
              tls_insecure_skip_verify
              # optional: tls_server_name 104.40.3.3
            }
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Port {server_port}
          }
        '';
      };
    };
  };
}
