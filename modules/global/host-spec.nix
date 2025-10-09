# Specifications for host configuration
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Validation assertions for host configurations
  config = {
    assertions = lib.flatten (
      lib.mapAttrsToList (hostname: hostCfg: [
        {
          assertion = !hostCfg.network.vpn or false || hostCfg.network.wg != null;
          message = ''
            Host '${hostname}' has VPN enabled but no WireGuard configuration.
            Either set network.vpn = false or provide network.wg configuration.
          '';
        }
        {
          assertion = !hostCfg.isMinimal or false || (!hostCfg.gnome or false && !hostCfg.niri or false);
          message = ''
            Host '${hostname}' is marked as minimal but has desktop environment enabled.
            Minimal hosts cannot have gnome or niri enabled.
          '';
        }
      ]) config.hostSpec
    );
  };

  options.hostSpec = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          ## User configuration ##
          user = lib.mkOption {
            type = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Username for the host's primary user";
                };

                uid = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  description = "User ID";
                  default = null;
                  example = 1000;
                };

                group = lib.mkOption {
                  type = lib.types.str;
                  description = "Primary group for the user";
                  default = "users";
                };

                shell = lib.mkOption {
                  type = lib.types.package;
                  description = "Default shell for the user";
                  default = pkgs.fish;
                  example = pkgs.bash;
                };
              };
            };
            description = "User configuration for this host";
          };

          ## Mount points ##
          mounts = lib.mkOption {
            type = lib.types.submodule {
              options = {
                fast = lib.mkOption {
                  type = lib.types.bool;
                  description = "Mount the /fast storage pool";
                  default = false;
                };

                tank = lib.mkOption {
                  type = lib.types.bool;
                  description = "Mount the /tank storage pool";
                  default = false;
                };

                store = lib.mkOption {
                  type = lib.types.bool;
                  description = "Mount the /store storage pool";
                  default = false;
                };

                hold = lib.mkOption {
                  type = lib.types.bool;
                  description = "Mount the /hold storage pool";
                  default = false;
                };

                repo = lib.mkOption {
                  type = lib.types.bool;
                  description = "Mount the /repo storage pool";
                  default = true;
                  # Almost all hosts should have /repo mounted its where Nix config lives
                };
              };
            };
            description = "Storage mount points for this host";
            default = { };
          };

          ## Network configuration ##
          network = lib.mkOption {
            type = lib.types.submodule {
              options = {
                hostName = lib.mkOption {
                  type = lib.types.str;
                  description = "The hostname of the host";
                };

                ip = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "IP address for this host";
                  default = null;
                  example = "192.168.1.100";
                };

                firewall = lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      allowedTCPPorts = lib.mkOption {
                        type = lib.types.listOf lib.types.port;
                        description = "Allowed TCP ports for this host";
                        default = [ ];
                        example = [
                          22
                          80
                          443
                        ];
                      };

                      allowedTCPPortRanges = lib.mkOption {
                        type = lib.types.listOf (
                          lib.types.submodule {
                            options = {
                              from = lib.mkOption {
                                type = lib.types.port;
                                description = "Starting port in range";
                              };
                              to = lib.mkOption {
                                type = lib.types.port;
                                description = "Ending port in range";
                              };
                            };
                          }
                        );
                        description = "Allowed TCP port ranges for this host";
                        default = [ ];
                      };

                      allowedUDPPorts = lib.mkOption {
                        type = lib.types.listOf lib.types.port;
                        description = "Allowed UDP ports for this host";
                        default = [ ];
                        example = [
                          53
                          123
                        ];
                      };

                      allowedUDPPortRanges = lib.mkOption {
                        type = lib.types.listOf (
                          lib.types.submodule {
                            options = {
                              from = lib.mkOption {
                                type = lib.types.port;
                                description = "Starting port in range";
                              };
                              to = lib.mkOption {
                                type = lib.types.port;
                                description = "Ending port in range";
                              };
                            };
                          }
                        );
                        description = "Allowed UDP port ranges for this host";
                        default = [ ];
                      };
                    };
                  };
                  description = "Firewall configuration for this host";
                  default = { };
                };

                wg = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        publicKey = lib.mkOption {
                          type = lib.types.str;
                          description = "WireGuard public key for this host";
                        };
                        address = lib.mkOption {
                          type = lib.types.str;
                          description = "IP address for WireGuard interface";
                          example = "10.100.0.2/32";
                        };
                        endpoint = lib.mkOption {
                          type = lib.types.nullOr lib.types.str;
                          description = "WireGuard server endpoint (for clients)";
                          default = null;
                          example = "vpn.example.com:51820";
                        };
                        persistentKeepalive = lib.mkOption {
                          type = lib.types.nullOr lib.types.int;
                          description = "Persistent keepalive interval in seconds";
                          default = null;
                          example = 25;
                        };
                        allowedIPs = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          description = "List of allowed IP ranges for this peer";
                          default = [
                            "0.0.0.0/0"
                            "::/0"
                          ];
                          example = [ "10.100.0.0/24" ];
                        };
                      };
                    }
                  );
                  description = "WireGuard VPN configuration for this host (non-sensitive parts)";
                  default = null;
                };

                vpn = lib.mkOption {
                  type = lib.types.bool;
                  description = "Enable VPN to nexus server";
                  default = false;
                };
              };
            };
            description = "Network configuration for this host";
          };

          ## Host characteristics ##
          isArm = lib.mkOption {
            type = lib.types.bool;
            description = "Host is ARM architecture (aarch64)";
            default = false;
          };

          isExternal = lib.mkOption {
            type = lib.types.bool;
            description = "Host is external (not on local network)";
            default = false;
          };

          isMinimal = lib.mkOption {
            type = lib.types.bool;
            description = "Host uses minimal configuration (No home-manager)";
            default = false;
          };

          isServer = lib.mkOption {
            type = lib.types.bool;
            description = "Host is a server (no desktop environment)";
            default = false;
          };

          ## Desktop environments ##
          gnome = lib.mkOption {
            type = lib.types.bool;
            description = "Enable GNOME DE";
            default = false;
          };

          niri = lib.mkOption {
            type = lib.types.bool;
            description = "Enable Niri WM";
            default = false;
          };

          autoLogin = lib.mkOption {
            type = lib.types.bool;
            description = "Enable automatic login for the primary user";
            default = true;
          };
        };
      }
    );
    description = "Host configuration specifications";
    default = { };
  };
}
