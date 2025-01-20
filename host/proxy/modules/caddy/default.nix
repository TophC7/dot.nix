{
  services.caddy = {
    enable = true;
    virtualHosts = {
      "ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy 104.40.4.44:80
        '';
      };

      "adguard.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy 104.40.4.1:81
        '';
      };

      "auth.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:9000 {
            header_up Host {host}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Protocol {scheme}
            header_up X-Forwarded-Port {server_port}
          }
        '';
      };

      "cloudflared.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.8:14333
        '';
      };

      "drive.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.24:8181 {
            header_up Host {host}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Protocol {scheme}
            header_up X-Forwarded-Port {server_port}
          }
        '';
      };

      "frp.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:4041
        '';
      };

      "grafana.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:3001
        '';
      };

      "git.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:3003
        '';
      };

      "influx.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:8086
        '';
      };

      "home.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:7475
        '';
      };

      "komodo.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:9120
        '';
      };

      "mail.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:9002
        '';
      };

      "map.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:25566
        '';
      };

      "opn.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy 104.40.4.1
        '';
      };

      "pve.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy 10.163.22.82:8006 {
              transport http {
                  tls_insecure_skip_verify
              }
          }
        '';
      };

      "upsnap.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:8090
        '';
      };
    };
  };
}
