# Specifications For Secret Data Structures
{
  pkgs,
  config,
  lib,
  ...
}:
let
  ## SSH key creation function ##
  mkSshKeyFile =
    name: content:
    pkgs.writeTextFile {
      name = "ssh-key-${name}";
      text = content;
      executable = false;
      checkPhase = ''
        grep -q "BEGIN OPENSSH PRIVATE KEY" "$out" || (echo "Invalid SSH key format"; exit 1)
      '';
    };

  ## GPG key creation function ##
  mkGpgKeyFile =
    name: content:
    pkgs.writeTextFile {
      name = "gpg-key-${name}";
      text = content;
      executable = false;
      checkPhase = ''
        grep -q "BEGIN PGP PRIVATE KEY BLOCK" "$out" || (echo "Invalid GPG key format"; exit 1)
      '';
    };
in
{
  options.secretsSpec = {
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

            ## SSH configuration ##
            ssh = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  publicKeys = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "SSH public keys for the user";
                    default = [ ];
                  };
                  privateKeyContents = lib.mkOption {
                    type = lib.types.attrsOf lib.types.str;
                    description = "SSH private key contents keyed by name";
                    default = { };
                  };
                  privateKeys = lib.mkOption {
                    type = lib.types.attrsOf lib.types.path;
                    description = "SSH private key file paths keyed by name";
                    default = { };
                    apply =
                      _:
                      let
                        userName = config.hostSpec.username;
                        userConfig = config.secretsSpec.users.${userName} or { };
                        privateKeyContents = userConfig.ssh.privateKeyContents or { };
                      in
                      lib.mapAttrs (name: content: mkSshKeyFile "${userName}-${name}" content) privateKeyContents;
                  };
                  config = lib.mkOption {
                    type = lib.types.path;
                    description = "SSH config file path";
                  };
                  knownHosts = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "SSH known hosts entries";
                    default = [ ];
                  };
                };
              };
              default = { };
              description = "SSH configuration for the user";
            };

            ## GPG configuration ##
            gpg = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  publicKey = lib.mkOption {
                    type = lib.types.str;
                    description = "GPG public key content";
                    default = "";
                  };
                  privateKeyContents = lib.mkOption {
                    type = lib.types.str;
                    description = "GPG private key content";
                    default = "";
                  };
                  privateKey = lib.mkOption {
                    type = lib.types.path;
                    description = "GPG private key file path";
                    default = null;
                    apply =
                      _:
                      let
                        userName = config.hostSpec.username;
                        userConfig = config.secretsSpec.users.${userName} or { };
                        privateKeyContent = userConfig.gpg.privateKeyContents or "";
                      in
                      if privateKeyContent != "" then mkGpgKeyFile userName privateKeyContent else null;
                  };
                  trust = lib.mkOption {
                    type = lib.types.str;
                    description = "GPG trust database content (base64)";
                    default = "";
                  };
                };
              };
              default = { };
              description = "GPG configuration for the user";
            };

            ## SMTP configuration ##
            smtp = lib.mkOption {
              type = lib.types.submodule {
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
                };
              };
              description = "SMTP configuration for the user";
              default = null;
            };
          };
        }
      );
      description = "User information secrets";
      default = { };
    };

    ## Firewall configurations by host ##
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

    ## API keys ##
    api = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "API keys keyed by service name";
      default = { };
    };

    ## Docker environment variables ##
    docker = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      description = "Docker environment variables keyed by container name";
      default = { };
    };
  };
}
