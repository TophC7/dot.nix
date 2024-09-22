{
    users.users.nginx.extraGroups = [ "acme" ];

    # Nginx
    services.nginx = {
        enable = true;
        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        
        virtualHosts = {
            "ryot.foo" = {
                http2 = true;
                forceSSL = true;
                useACMEHost = "ryot.foo";
                locations."/".proxyPass = "http://0.0.0.0:8080";
            };

            "*.ryot.foo" = {
                http2 = true;
                forceSSL = true;
                useACMEHost = "ryot.foo";
                locations."/" = {
                    proxyPass = "http://0.0.0.0:8080";
                    proxyWebsockets = true;
                    extraConfig = ''
                        proxy_ssl_server_name on;
                        proxy_pass_header Authorization;
                    '';
                };
            };
        };
    };
}