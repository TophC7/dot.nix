{
  services.caddy = {
    enable = true;
    virtualHosts = {

      ## TOPH.CC ##

      "blog.toph.cc" = {
        useACMEHost = "toph.cc";
        extraConfig = ''
          reverse_proxy localhost:2368
        '';
      };

      ## RYOT.FOO ##

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
          route {
            # 1) Proxy all outpost requests back to Authentik
            reverse_proxy /outpost.goauthentik.io/* localhost:9000

            # 2) Protect everything else via forward_auth
            forward_auth localhost:9000 {
              uri     /outpost.goauthentik.io/auth/caddy
              # copy user info headers from Authentik
              copy_headers  X-Authentik-Username X-Authentik-Groups \
                            X-Authentik-Entitlements X-Authentik-Email \
                            X-Authentik-Name X-Authentik-Uid \
                            X-Authentik-Jwt X-Authentik-Meta-Jwks \
                            X-Authentik-Meta-Outpost X-Authentik-Meta-Provider \
                            X-Authentik-Meta-App X-Authentik-Meta-Version
              trusted_proxies private_ranges
            }

            # 3) If authenticated, proxy to your FRP UI
            reverse_proxy localhost:4041 {
              header_up Host             {host}
              header_up X-Real-IP         {remote}
              header_up X-Forwarded-For   {remote}
              header_up X-Forwarded-Proto {scheme}
              header_up X-Forwarded-Port  {server_port}
            }
          }
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

      "map.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:25566
        '';
      };

      "outline.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:3480 
        '';
      };

      "plane.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:3000 
        '';
      };
    };
  };
}
