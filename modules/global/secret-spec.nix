# Specifications For Secret Data Structures
{
  pkgs,
  config,
  lib,
  ...
}:
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

    ## Service configurations ##
    service = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      description = "Service-specific secrets and configuration keyed by service name";
      default = { };
      example = {
        "wg-nexus" = {
          privateKey = "...";
          presharedKey = "...";
        };
        filerun = {
          DB_PASSWORD = "...";
          SECRET_KEY = "...";
        };
        cloudflare = {
          api_token = "...";
          zone_id = "...";
        };
      };
    };
  };
}
