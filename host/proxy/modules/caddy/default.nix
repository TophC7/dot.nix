{
  services.caddy = {
    enable = true;
    virtualHosts = {
      "cloudflared.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:14333
        '';
      };
    };
  };
}
