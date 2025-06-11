{
  services.caddy = {
    enable = true;
    virtualHosts = {
      "upsnap.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:8090
        '';
      };

      "sock.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy localhost:9120
        '';
      };
    };
  };
}
