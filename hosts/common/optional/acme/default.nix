{
  config,
  lib,
  pkgs,
  ...
}:
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
      "goldenlemon.cc" = {
        extraDomainNames = [ "*.goldenlemon.cc" ];
      };

      # "kwahson.com" = {
      #   extraDomainNames = [ "*.kwahson.com" ];
      # };

      # "kwahson.xyz" = {
      #   extraDomainNames = [ "*.kwahson.xyz" ];
      # };

      # "toph.cc" = {
      #   extraDomainNames = [ "*.toph.cc" ];
      # };

      "ryot.foo" = {
        extraDomainNames = [ "*.ryot.foo" ];
      };
    };
  };
}
