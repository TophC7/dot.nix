{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.olm;
in
{
  options.services.olm = {
    enable = mkEnableOption "OLM tunneling client for Pangolin networks";

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to start OLM automatically at boot. Set to false for manual control via systemctl.";
    };

    id = mkOption {
      type = types.str;
      description = "OLM client identifier for authentication";
    };

    secret = mkOption {
      type = types.str;
      description = "OLM secret for authentication";
    };

    endpoint = mkOption {
      type = types.str;
      default = "https://pangolin.ryot.foo";
      description = "Pangolin endpoint URL for WebSocket connection";
    };

    endpointIP = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1.12.123.123";
      description = "Direct IP address for the endpoint to bypass DNS/proxy. When set, adds a hosts entry for the domain.";
    };

    mtu = mkOption {
      type = types.int;
      default = 1280;
      description = "Network interface MTU";
    };

    dns = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1.1.1.1";
      description = "DNS server to use. If not set, uses system default DNS.";
    };

    logLevel = mkOption {
      type = types.enum [
        "DEBUG"
        "INFO"
        "WARN"
        "ERROR"
        "FATAL"
      ];
      default = "INFO";
      description = "Logging verbosity level";
    };

    pingInterval = mkOption {
      type = types.str;
      default = "3s";
      description = "Server ping frequency";
    };

    pingTimeout = mkOption {
      type = types.str;
      default = "5s";
      description = "Ping response timeout";
    };

    holepunch = mkOption {
      type = types.bool;
      default = null;
      description = "Enable NAT traversal (experimental)";
    };

    healthFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path for connection status tracking";
    };

    interfaceName = mkOption {
      type = types.str;
      default = "olm0";
      description = "Name of the WireGuard interface to create";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to OLM configuration file (overrides other options)";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.olm-tunnel;
      defaultText = literalExpression "pkgs.olm-tunnel";
      description = "OLM package to use";
    };

    enableGnomeExtension = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GNOME Shell extension for toggling OLM from the panel";
    };
  };

  config = mkIf cfg.enable {
    # Create systemd service
    systemd.services.olm = mkMerge [
      {
        description = "OLM tunneling client for Pangolin networks";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = mkIf cfg.autoStart [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "10s";

          # Security hardening
          DynamicUser = false; # Need root for WireGuard interface
          User = "root";
          Group = "root";

          # Environment variables (as alternative/supplement to CLI args)
          # Environment = [
          #   "PANGOLIN_ENDPOINT=${cfg.endpoint}"
          #   "OLM_ID=${cfg.id}"
          #   "OLM_SECRET=${cfg.secret}"
          #   "OLM_MTU=${toString cfg.mtu}"
          #   "OLM_DNS=${cfg.dns}"
          #   "OLM_LOG_LEVEL=${cfg.logLevel}"
          # ];

          # Capabilities for network interface management
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_RAW"
          ];
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_RAW"
          ];

          # Network isolation (but allow network access)
          PrivateNetwork = false;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];

          # Filesystem hardening
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          ReadWritePaths = optionals (cfg.healthFile != null) [ (dirOf cfg.healthFile) ];

          # Process hardening
          NoNewPrivileges = true;
          ProtectKernelTunables = false; # Need to modify network settings
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = false; # Go binaries may need this
          RestrictRealtime = true;
          RestrictSUIDSGID = true;

          # System call filtering
          SystemCallFilter = [
            "@system-service"
            "@network-io"
            "~@privileged"
            "~@resources"
          ];
          SystemCallArchitectures = "native";
        };

        script =
          if cfg.configFile != null then
            ''
              exec ${cfg.package}/bin/olm --config ${cfg.configFile}
            ''
          else
            ''
              exec ${cfg.package}/bin/olm \
                --id "${cfg.id}" \
                --secret "${cfg.secret}" \
                --endpoint "${cfg.endpoint}" \
                --mtu "${toString cfg.mtu}" \
                ${optionalString (cfg.dns != null) "--dns \"${cfg.dns}\""} \
                --log-level "${cfg.logLevel}" \
                --ping-interval "${cfg.pingInterval}" \
                --ping-timeout "${cfg.pingTimeout}" \
                --interface "${cfg.interfaceName}" \
                ${optionalString cfg.holepunch "--holepunch true"} \
                ${optionalString (cfg.healthFile != null) "--health-file ${cfg.healthFile}"}
            '';
      }
    ];

    # Networking configuration
    networking = {
      # Open WireGuard port if needed
      firewall = mkIf cfg.holepunch {
        allowedUDPPorts = [ 51820 ];
      };
    };

    # Add GNOME extension if enabled
    environment.systemPackages = mkIf cfg.enableGnomeExtension [
      pkgs.olm-toggle
    ];

    # Add polkit rule for passwordless toggle
    security.polkit.extraConfig = mkIf cfg.enableGnomeExtension (
      builtins.readFile "${pkgs.olm-toggle}/share/polkit-1/rules.d/olm-toggle.rules"
    );
  };
}
