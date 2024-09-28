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
            
            "cloud.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy https://104.40.4.24:443 {
                        transport http {
                            tls_insecure_skip_verify
                        }
                    }
                '';
            };

            "cloudflared.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.8:14333
                '';
            };

            "dash.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:3001
                '';
            };

            "dazzle.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:8070
                '';
            };

            "dockge.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:5001
                '';
            };

            "drive.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:8080
                '';
            };

            "frp.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:4041
                '';
            };
            

            "home.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:7575
                '';
            };
            

            "nginx.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = ''
                    reverse_proxy http://104.40.4.44:81
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
