# Specifications For Secret Data Structures
{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Function to create a private key file in the Nix store with proper permissions
  mkSshKeyFile =
    name: content:
    pkgs.writeTextFile {
      name = "ssh-key-${name}";
      text = content;
      executable = false;
      checkPhase = ''
        # Verify it's a valid SSH key (optional)
        grep -q "BEGIN OPENSSH PRIVATE KEY" "$out" || (echo "Invalid SSH key format"; exit 1)
      '';
    };

  # Function to build an Apprise URL from SMTP settings
  buildAppriseUrl =
    {
      host,
      user,
      password,
      from,
      ...
    }:
    "mailtos://_?user=${user}&pass=${password}&smtp=${host}&from=${from}&to=${user}";
in
{
  options.secretsSpec = {
    ssh = lib.mkOption {
      type = lib.types.submodule {
        options = {
          # privateKeys are set up automagically 🌠, see config below
          privateKeyContents = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            description = "SSH private key contents keyed by name";
            default = { };
          };
          privateKeys = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            description = "SSH private key file paths keyed by name";
            # default = { };
            readOnly = true;
          };
          publicKeys = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            description = "SSH public keys keyed by name";
            default = { };
          };
          knownHosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "SSH known hosts entries";
            default = [ ];
          };
        };
      };
      default = { };
      description = "SSH key related secrets";
    };

    api = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "API keys keyed by service name";
      default = { };
    };

    docker = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      description = "Docker environment variables keyed by container name";
      default = { };
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            hashedPassword = lib.mkOption {
              type = lib.types.str;
              description = "Hashed password for the user"; # nix-shell -p whois --run 'mkpasswd --method=sha-512 --rounds=656000'
            };
            email = lib.mkOption {
              type = lib.types.str;
              description = "Email address for the user";
            };
            handle = lib.mkOption {
              type = lib.types.str;
              description = "The handle of the user (eg: github user)";
            };
            fullName = lib.mkOption {
              type = lib.types.str;
              description = "Full name of the user";
            };
            sshKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "SSH public keys for the user";
              default = [ ];
            };
            smtp = lib.mkOption {
              type = lib.types.submodule (
                { config, ... }:
                {
                  options = {
                    host = lib.mkOption {
                      type = lib.types.str;
                      description = "SMTP server hostname";
                    };
                    user = lib.mkOption {
                      type = lib.types.str;
                      description = "SMTP username for authentication";
                    };
                    password = lib.mkOption {
                      type = lib.types.str;
                      description = "SMTP password for authentication";
                    };
                    port = lib.mkOption {
                      type = lib.types.port;
                      description = "SMTP server port";
                      default = 587;
                    };
                    from = lib.mkOption {
                      type = lib.types.str;
                      description = "Email address to send from";
                    };
                    notifyUrl = lib.mkOption {
                      type = lib.types.str;
                      description = "Apprise URL for sending notifications via this SMTP account";
                    };
                  };
                  config = {
                    notifyUrl = "mailtos://_?user=${config.user}&pass=${config.password}&smtp=${config.host}&from=${config.from}&to=${config.user}";
                  };
                }
              );
              description = "SMTP configuration for the user";
              default = null;
            };
          };
        }
      );
      description = "User information secrets";
      default = { };
    };

    firewall = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            allowedTCPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              description = "Allowed TCP ports for this host";
              default = [ ];
              # example = [
              #   22
              #   80
              #   443
              # ];
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
              # example = [
              #   {
              #     from = 25565;
              #     to = 25570;
              #   }
              # ];
            };
            allowedUDPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              description = "Allowed UDP ports for this host";
              default = [ ];
              # example = [
              #   53
              #   123
              # ];
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
              # example = [
              #   {
              #     from = 25565;
              #     to = 25570;
              #   }
              # ];
            };
          };
        }
      );
      description = "Firewall configuration by host";
      default = { };
    };
  };

  config.secretsSpec.ssh.privateKeys = lib.mapAttrs (
    name: content: mkSshKeyFile name content
  ) config.secretsSpec.ssh.privateKeyContents;
}
