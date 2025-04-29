{
  pkgs,
  config,
  ...
}:
let
  # Create a VERY simple environment file with absolutely minimal formatting
  cloudflareEnvFile = pkgs.writeText "cloudflare.env" ''
    CLOUDFLARE_DNS_API_TOKEN=${config.secretsSpec.api.cloudflare}
  '';
in
{
  environment.systemPackages = [ pkgs.lego ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "chris@toph.cc";
      dnsProvider = "cloudflare"; # Use Cloudflare's DNS
      environmentFile = cloudflareEnvFile;
      enableDebugLogs = true;
      extraLegoFlags = [
        "--dns.resolvers=1.1.1.1:53,8.8.8.8:53"
        "--dns.propagation-wait=60s" # Wait for 60 seconds for DNS propagation
        "--dns-timeout=60"
        "--http-timeout=60"
      ];
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
