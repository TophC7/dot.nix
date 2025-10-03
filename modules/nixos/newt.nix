{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.newt;
in
{
  # TODO: Might want to change my newt.nix to not conflict with upstream module
  # For now this disables the upstream module
  disabledModules = [ "services/networking/newt.nix" ];

  options.services.newt = {
    enable = mkEnableOption "Newt container service";

    id = mkOption {
      type = types.str;
      description = "Newt ID for authentication";
    };

    image = mkOption {
      type = types.str;
      default = "fosrl/newt";
      description = "Docker image to use for Newt";
    };

    networkName = mkOption {
      type = types.str;
      default = "newt";
      description = "Docker network name to use";
    };

    networkAlias = mkOption {
      type = types.str;
      default = "newt";
      description = "Network alias for the container";
    };

    pangolinEndpoint = mkOption {
      type = types.str;
      default = "https://pangolin.ryot.foo";
      description = "Pangolin endpoint URL";
    };

    secret = mkOption {
      type = types.str;
      description = "Newt secret for authentication";
    };

    useHostNetwork = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use host networking instead of Docker networks";
    };

    extraNetworks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional Docker networks to connect the container to";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."newt" = {
      image = cfg.image;
      # Using command-line arguments instead of environment variables
      cmd = [
        "--id"
        cfg.id
        "--secret"
        cfg.secret
        "--endpoint"
        cfg.pangolinEndpoint
        "--docker-socket"
        "/var/run/docker.sock"
        "--accept-clients"
        "true"
        "--native" # Use native WireGuard interface (was USE_NATIVE_INTERFACES)
        "true"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:rw"
      ];
      log-driver = "journald";
      # Run as root with privileges for native WireGuard interface
      user = "root:root";
      extraOptions = [
        "--privileged" # Required for native WireGuard interface
        "--cap-add=NET_ADMIN" # Network administration capability
        "--cap-add=SYS_MODULE" # Load kernel modules if needed
      ]
      ++ (
        if cfg.useHostNetwork then
          [
            "--network=host"
          ]
        else
          [
            "--network-alias=${cfg.networkAlias}"
            "--network=${cfg.networkName}"
          ]
          ++ (map (net: "--network=${net}") cfg.extraNetworks)
      );
    };

    systemd.services."docker-newt" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = mkIf (!cfg.useHostNetwork) [
        "docker-network-${cfg.networkName}.service"
      ];
      requires = mkIf (!cfg.useHostNetwork) [
        "docker-network-${cfg.networkName}.service"
      ];
      partOf = [
        "docker-newt-root.target"
      ];
      wantedBy = [
        "docker-newt-root.target"
      ];
    };

    # Docker network service (only when not using host network)
    systemd.services."docker-network-${cfg.networkName}" = mkIf (!cfg.useHostNetwork) {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f ${cfg.networkName}";
      };
      script = ''
        docker network inspect ${cfg.networkName} || docker network create --driver bridge ${cfg.networkName}
      '';
      partOf = [ "docker-newt-root.target" ];
      wantedBy = [ "docker-newt-root.target" ];
    };

    # Root target
    systemd.targets."docker-newt-root" = {
      unitConfig = {
        Description = "Root target for Newt container and its network";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
