{
  config,
  pkgs,
  lib,
  consts,
  ...
}:
let
  frpToken = config.secretsSpec.api.frp;
  caenusIp = config.secretsSpec.network.caenus.ip;
  volumePath = "${consts.DATA_BASE_PATH}/frp";

  # FRP client configuration
  frpcConfig = pkgs.writeText "frpc.toml" ''
    # FRP Client Configuration - runs inside Pangolin's network
    serverAddr = "${caenusIp}"
    serverPort = 4040
    auth.method = "token"
    auth.token = "${frpToken}"

    # Transport settings
    transport.protocol = "tcp"

    # Pangolin services forwarded to caenus
    [[proxies]]
    name = "pangolin-http"
    type = "tcp"
    localIP = "104.40.1.11"
    localPort = 80
    remotePort = 80

    [[proxies]]
    name = "pangolin-https"
    type = "tcp"
    localIP = "104.40.1.11"
    localPort = 443
    remotePort = 443

    [[proxies]]
    name = "pangolin-ssh"
    type = "tcp"
    localIP = "104.40.1.11"
    localPort = 222
    remotePort = 222

    [[proxies]]
    name = "pangolin-wireguard-olm"
    type = "udp"
    localIP = "104.40.1.11"
    localPort = 51820
    remotePort = 51820

    [[proxies]]
    name = "pangolin-wireguard-vpn"
    type = "udp"
    localIP = "104.40.1.11"
    localPort = 51821
    remotePort = 51821

    [[proxies]]
    name = "pangolin-tunnels"
    type = "udp"
    localIP = "104.40.1.11"
    localPort = 21820
    remotePort = 21820

    [[proxies]]
    name = "pangolin-minecraft"
    type = "tcp"
    localIP = "104.40.1.11"
    localPort = 25565
    remotePort = 25565
  '';

  # Dockerfile for FRP client
  frpDockerfile = pkgs.writeText "Dockerfile.frpc" ''
    FROM golang:1.24-alpine AS builder

    ARG TARGETOS=linux
    ARG TARGETARCH=amd64
    ENV FRP_VERSION=0.65.0

    WORKDIR /build

    RUN apk add --no-cache make git \
        && git clone --depth 1 --branch v''${FRP_VERSION} https://github.com/fatedier/frp.git . \
        && make frpc

    FROM alpine:3.21
    RUN apk add --no-cache ca-certificates tzdata
    COPY --from=builder /build/bin/frpc /usr/bin/frpc
    ENTRYPOINT ["/usr/bin/frpc"]
    CMD ["-c", "/etc/frp/frpc.toml"]
  '';
in
{
  # Build FRP Docker image
  systemd.services.docker-frpc-build = {
    description = "Build FRP client Docker image";
    wantedBy = [ "multi-user.target" ];
    before = [ "docker-pangolin-frpc.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Create build directory
      mkdir -p /tmp/frpc-build
      cp ${frpDockerfile} /tmp/frpc-build/Dockerfile

      # Build the image
      ${pkgs.docker}/bin/docker build -t frpc-pangolin:latest /tmp/frpc-build

      # Clean up
      rm -rf /tmp/frpc-build
    '';
  };

  # FRP client container - runs in Pangolin's network namespace
  virtualisation.oci-containers.containers."pangolin-frpc" = {
    image = "frpc-pangolin:latest";
    volumes = [
      "${frpcConfig}:/etc/frp/frpc.toml:ro"
    ];
    dependsOn = [ "pangolin" ];

    # Use Pangolin's network namespace
    extraOptions = [
      "--network=container:pangolin"
    ];

    log-driver = "journald";
  };

  # Ensure FRP starts after Pangolin and stays running
  systemd.services."docker-pangolin-frpc" = {
    after = [
      "docker-pangolin.service"
      "docker-frpc-build.service"
    ];
    requires = [
      "docker-pangolin.service"
      "docker-frpc-build.service"
    ];
    partOf = [
      "docker-compose-pangolin-root.target"
    ];
    wantedBy = [
      "docker-compose-pangolin-root.target"
    ];
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartSec = lib.mkOverride 90 "10s";
    };
  };

  # Ensure old NixOS FRP service is disabled
  services.frp.enable = lib.mkForce false;
}
