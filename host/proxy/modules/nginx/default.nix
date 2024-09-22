{

    # INFO: migth need at some point so keeping it here

    # Nginx
    services.nginx = {
        enable = true;
        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Add a virtual host
        virtualHosts."ryot.com" = {};

    };
}