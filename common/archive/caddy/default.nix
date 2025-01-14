{
    services.caddy = {
        enable = true;

        virtualHosts = {
            "*.ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = builtins.readFile ./ryot.foo.conf;
            };
            
            "ryot.foo" = {
                useACMEHost = "ryot.foo";
                extraConfig = builtins.readFile ./ryot.foo.conf;
            };
        };
    };
}