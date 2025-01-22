{
  services.caddy = {
    enable = true;
    virtualHosts = {
      # "ryot.foo" = {
      #   useACMEHost = "ryot.foo";
      #   extraConfig = ''
      #     reverse_proxy 104.40.4.44:80
      #   '';
      # };

      "auth.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:9000 {
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
          reverse_proxy localhost:4041
        '';
      };

      "grafana.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:3001
        '';
      };

      "git.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:3003
        '';
      };

      "influx.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:8086
        '';
      };

      "home.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:7475
        '';
      };

      "komodo.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:9120
        '';
      };

      "mail.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:9002
        '';
      };

      "map.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:25566
        '';
      };

      "upsnap.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:8090
        '';
      };
    };
  };
}
