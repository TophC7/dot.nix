{
  services.caddy = {
    enable = true;
    virtualHosts = {
      "drive.ryot.foo" = {
        useACMEHost = "ryot.foo";
        extraConfig = ''
          reverse_proxy http://localhost:8181 {
            header_up Host {host}
            # header_up X-Forwarded-For {remote}
            # header_up X-Forwarded-Proto {scheme}
            # header_up X-Forwarded-Protocol {scheme}
            # header_up X-Forwarded-Port {server_port}
          }
        '';
      };
    };
  };
}
