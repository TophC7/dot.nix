{ config, lib, pkgs, ... }: 
{
    
    # letsencrypt 
    security.acme = {
        acceptTerms = true;
        defaults = {
            email = "chris@toph.cc";
            dnsProvider = "cloudflare";
            environmentFile = ./cloudflare.ini;
        };
        certs = {
            "ryot.foo" = {
                extraDomainNames = ["*.ryot.foo"];
            };
        };
    };
}