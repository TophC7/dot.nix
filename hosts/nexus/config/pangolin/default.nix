{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  smtp = secrets.users.admin.smtp;
  pangolin = secrets.service.pangolin;

  # Create the configuration files as derivations
  pangolinConfigFile = pkgs.writeText "pangolin-config.yml" ''
    app:
      dashboard_url: "https://pangolin.ryot.foo"
      log_level: "debug"
      save_logs: true

    domains:
      domain1:
        base_domain: "ryot.foo"
        cert_resolver: "letsencrypt"
        prefer_wildcard_cert: true
      domain2:
        base_domain: "toph.cc"
        cert_resolver: "letsencrypt"
        prefer_wildcard_cert: true
      domain3:
        base_domain: "goldenlemon.cc"
        cert_resolver: "letsencrypt"
        prefer_wildcard_cert: true
      domain4:
        base_domain: "kwahson.xyz"
        cert_resolver: "letsencrypt"
        prefer_wildcard_cert: true

    server:
      external_port: 3000
      internal_port: 3001
      next_port: 3002
      internal_hostname: "pangolin"
      session_cookie_name: "p_session_token"
      resource_access_token_param: "p_token"
      resource_access_token_headers:
        id: "P-Access-Token-Id"
        token: "P-Access-Token"
      resource_session_request_param: "p_session_request"
      secret: "${pangolin.SECRET}"

    traefik:
      cert_resolver: "letsencrypt"
      http_entrypoint: "web"
      https_entrypoint: "websecure"

    gerbil:
      start_port: 51820
      base_endpoint: "pangolin.ryot.foo"
      use_subdomain: false
      block_size: 24
      site_block_size: 30
      subnet_group: 10.11.0.1/24

    rate_limits:
      global:
        window_minutes: 1
        max_requests: 100

    email:
      smtp_host: "${smtp.host}"
      smtp_port: ${toString smtp.port}
      smtp_user: "${smtp.user}"
      smtp_pass: "${smtp.password}"
      no_reply: "no-reply@ryot.foo"

    users:
      server_admin:
        email: "${pangolin.USER}"
        password: "${pangolin.PASSWORD}"

    flags:
      require_email_verification: true
      disable_signup_without_invite: true
      disable_user_create_org: true
      allow_raw_resources: true
      allow_base_domain_resources: true
  '';

  traefikConfigFile = pkgs.writeText "traefik-config.yml" ''
    api:
      insecure: true
      dashboard: true

    providers:
      http:
        endpoint: "http://pangolin:3001/api/v1/traefik-config"
        pollInterval: "5s"
      file:
        filename: "/etc/traefik/dynamic_config.yml"

    experimental:
      plugins:
        badger:
          moduleName: "github.com/fosrl/badger"
          version: "v1.2.0"

    log:
      level: "DEBUG"
      format: "common"

    certificatesResolvers:
      letsencrypt:
        acme:
          dnsChallenge:
            provider: cloudflare
            delayBeforeCheck: 60
            resolvers:
              - "1.1.1.1:53"
              - "8.8.8.8:53"
          email: chris@toph.cc
          storage: "/letsencrypt/acme.json"
          caServer: "https://acme-v02.api.letsencrypt.org/directory"

    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"
        transport:
          respondingTimeouts:
            readTimeout: "30m"
        http:
          tls:
            certResolver: "letsencrypt"
      tcp-222:
        address: ":222/tcp"
      udp-25565:
        address: ":25565/udp"

    serversTransport:
      insecureSkipVerify: true
  '';

  dynamicConfigFile = pkgs.writeText "dynamic-config.yml" ''
    http:
      middlewares:
        redirect-to-https:
          redirectScheme:
            scheme: https

      routers:
        # HTTP to HTTPS redirect router
        main-app-router-redirect:
          rule: "Host(`pangolin.ryot.foo`)"
          service: next-service
          entryPoints:
            - web
          middlewares:
            - redirect-to-https

        # Next.js router
        next-router:
          rule: "Host(`pangolin.ryot.foo`) && !PathPrefix(`/api/v1`)"
          service: next-service
          entryPoints:
            - websecure
          tls:
            certResolver: letsencrypt
            domains:
              - main: "ryot.foo"
                sans:
                  - "*.ryot.foo"

        # API router
        api-router:
          rule: "Host(`pangolin.ryot.foo`) && PathPrefix(`/api/v1`)"
          service: api-service
          entryPoints:
            - websecure
          tls:
            certResolver: letsencrypt

        # WebSocket router
        ws-router:
          rule: "Host(`pangolin.ryot.foo`)"
          service: api-service
          entryPoints:
            - websecure
          tls:
            certResolver: letsencrypt

      services:
        next-service:
          loadBalancer:
            servers:
              - url: "http://pangolin:3002"

        api-service:
          loadBalancer:
            servers:
              - url: "http://pangolin:3000"
  '';

  keyFile = pkgs.writeText "pangolin-key" pangolin.KEY;
in
{
  imports = lib.fs.scanPaths ./.;

  ## Tmp files and Service to Avoid symlinks
  systemd.tmpfiles.rules = [
    "d /etc/pangolin/config 0755 root root -"
    "d /etc/pangolin/config/traefik 0755 root root -"
    "d /etc/pangolin/config/letsencrypt 0755 root root -"
  ];

  systemd.services.pangolin-config-sync = {
    description = "Sync Pangolin configuration files";
    wantedBy = [ "multi-user.target" ];
    before = [ "docker-compose-pangolin-root.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      cp ${keyFile} /etc/pangolin/config/key
      chmod 0600 /etc/pangolin/config/key
      cp ${pangolinConfigFile} /etc/pangolin/config/config.yml
      cp ${traefikConfigFile} /etc/pangolin/config/traefik/traefik_config.yml
      cp ${dynamicConfigFile} /etc/pangolin/config/traefik/dynamic_config.yml
    '';
  };
}
