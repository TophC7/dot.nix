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

      "cloudflared.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:14333
        '';
      };

      # "drive.ryot.foo" = {
      #   useACMEHost = "ryot.foo";
      #   extraConfig = ''
      #     reverse_proxy http://104.40.4.24:8181 {
      #       header_up Host {host}
      #       header_up X-Forwarded-For {remote}
      #       header_up X-Forwarded-Proto {scheme}
      #       header_up X-Forwarded-Protocol {scheme}
      #       header_up X-Forwarded-Port {server_port}
      #     }
      #   '';
      # };

      # "opn.ryot.foo" = {
      #   useACMEHost = "ryot.foo";
      #   extraConfig = ''
      #     reverse_proxy 104.40.4.1
      #   '';
      # };

      # "pve.ryot.foo" = {
      #   useACMEHost = "ryot.foo";
      #   extraConfig = ''
      #     reverse_proxy 10.163.22.82:8006 {
      #         transport http {
      #             tls_insecure_skip_verify
      #         }
      #     }
      #   '';
      # };
    };
  };
}
