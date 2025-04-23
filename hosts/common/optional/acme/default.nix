{
  pkgs,
  config,
  ...
}:
let
  cloudflare = pkgs.writeTextFile {
    name = "cloudflare.ini";
    text = ''
      CF_DNS_API_TOKEN=${config.secretsSpec.api.cloudflare}
    '';
  };
in
{

  # letsencrypt
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@toph.cc";
      dnsProvider = "cloudflare";
      environmentFile = cloudflare;
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
