{
  # FIXME: This works IN server but not connecting via ssh to caenus
  services.caddy = {
    enable = true;
    virtualHosts = {

      # "ryot.foo" = {
      #     useACMEHost = "ryot.foo";
      #     extraConfig = ''
      #         reverse_proxy 104.40.4.44:80
      #     '';
      # };

      "map.goldenlemon.cc" = {
        useACMEHost = "goldenlemon.cc";
        extraConfig = ''
          reverse_proxy http://104.40.4.44:25566
        '';
      };
    };
  };
}
