{
    # letsencrypt this wont do shit but allows things to work
    # i take care of this on dockge lxc
    security.acme = {
        acceptTerms = true;
        defaults.email = "chris@toph.cc";
    };

    # Nginx
    services.nginx = {

        enable = true;

        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Only allow PFS-enabled ciphers with AES256
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        # Setup Nextcloud virtual host to listen on ports
        virtualHosts = {

        "cloud.ryot.foo" = {
            ## Force HTTP redirect to HTTPS
            forceSSL = true;
            ## LetsEncrypt
            enableACME = true;
            };
        };
    };
}