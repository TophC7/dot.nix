# Secret data implementation
# This file should be encrypted with git-crypt
{
  pkgs,
  config,
  lib,
  ...
}:

let
  ## SSH Keys ##
  server = {
    priv = ''
      -----BEGIN OPENSSH PRIVATE KEY-----
      [... example private key content ...]
      -----END OPENSSH PRIVATE KEY-----
    '';

    pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample123ServerKey456 server";
  };

  git = {
    priv = ''
      -----BEGIN OPENSSH PRIVATE KEY-----
      [... example private key content ...]
      -----END OPENSSH PRIVATE KEY-----
    '';

    pub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample123GitKey456 git";
  };

  # Default SSH config for main user
  sshConfig = pkgs.writeText "ssh-config" ''
    Host git.example.com
      IdentityFile "${config.hostSpec.home}/.ssh/git"

    Host *
      ForwardAgent no
      AddKeysToAgent yes
      Compression no
      ServerAliveInterval 5
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no

      IdentityFile "${config.hostSpec.home}/.ssh/server"
      UpdateHostKeys ask
  '';

  # Alternative SSH config for secondary user
  sshConfig-alt = pkgs.writeText "ssh-config" ''
    Host git.example.com
      IdentityFile "${config.hostSpec.home}/.ssh/git"

    Host *
      ForwardAgent no
      AddKeysToAgent yes
      Compression no
      ServerAliveInterval 5
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no

      UpdateHostKeys ask
  '';

  ## GPG Keys, WIP ##
  mainUser = {
    priv = ''
      -----BEGIN PGP PRIVATE KEY BLOCK-----
      [... example GPG private key content ...]
      -----END PGP PRIVATE KEY BLOCK-----
    '';

    pub = ''
      -----BEGIN PGP PUBLIC KEY BLOCK-----
      [... example GPG public key content ...]
      -----END PGP PUBLIC KEY BLOCK-----
    '';

    trust = ''
      IyBFeGFtcGxlIHRydXN0IGRhdGEgZm9yIEdQRyBrZXkKRXhhbXBsZUtleUZpbmdlcnByaW50OjY6Cg==
    '';
  };
in

{
  secretsSpec = {
    # User account information
    users = {

      admin = {
        # SMTP Only, not a login user
        smtp = {
          host = "smtp.example.com";
          user = "admin@example.com";
          password = "example_smtp_password_123";
          port = 587;
          from = "admin@example.com";
        };
      };

      alice = {
        hashedPassword = ''$6$rounds=656000$ExampleSalt123$ExampleHashedPasswordHere123''; # example_password
        email = "alice@example.com";
        handle = "alice123";
        fullName = "Alice Smith";

        smtp = {
          host = "smtp.example.com";
          user = "alice@example.com";
          password = "alice_smtp_password_456";
          port = 587;
          from = "alice@example.com";
        };

        ssh = {
          publicKeys = [
            server.pub
          ];
          privateKeyContents = {
            server = server.priv;
            git = git.priv;
          };
          config = sshConfig;
        };

        gpg = {
          publicKey = mainUser.pub;
          privateKeyContents = mainUser.priv;
          trust = mainUser.trust;
        };
      };

      bob = {
        hashedPassword = ''$6$rounds=656000$AnotherSalt456$AnotherExampleHashedPassword789''; # another_password
        email = "bob@example.com";
        handle = "bobuser";
        fullName = "Bob Johnson";

        ssh = {
          publicKeys = [
            server.pub
          ];
          privateKeyContents = {
            server = server.priv;
            git = git.priv;
          };
          config = sshConfig;
        };
      };

      charlie = {
        hashedPassword = ''$6$rounds=656000$ThirdSalt789$ThirdExampleHashedPassword012''; # third_password
        email = "charlie@example.com";
        handle = "charlie_dev";
        fullName = "Charlie Wilson";

        ssh = {
          publicKeys = [
            server.pub
          ];
          config = sshConfig-alt;
        };
      };
    };

    # Firewall configurations by host
    firewall = {
      webserver = {
        allowedTCPPorts = [
          22 # SSH
          80 # HTTP
          443 # HTTPS
          3000 # Application
          5432 # PostgreSQL
        ];

        allowedUDPPorts = [
          53 # DNS
        ];
      };

      appserver = {
        allowedTCPPorts = [
          22 # SSH
          80 # HTTP
          443 # HTTPS
          3001 # Grafana
          8080 # Application
          9000 # Admin panel
        ];

        allowedTCPPortRanges = [
          {
            from = 3000;
            to = 3010;
          }
        ];

        allowedUDPPorts = [
          8089 # Monitoring
        ];
      };

      database = {
        allowedTCPPorts = [
          22 # SSH
          5432 # PostgreSQL
          3306 # MySQL
        ];
      };
    };

    # API secrets for various services
    api = {
      cloudflare = "example_cloudflare_api_token_123456";
      github = "ghp_example_github_token_123456789";
      discord = "example_discord_bot_token_987654321";
    };

    # Docker environment variables for services
    docker = {
      app_auth = {
        DATABASE_URL = "postgresql://app_user:example_db_password@database:5432/app_db";
        JWT_SECRET = "example_jwt_secret_key_very_long_and_secure";
        SMTP_HOST = "smtp.example.com";
        SMTP_USER = "app@example.com";
        SMTP_PASSWORD = "example_app_smtp_password";
        SMTP_PORT = "587";
        REDIS_URL = "redis://redis:6379";
        SESSION_SECRET = "example_session_secret_also_very_long";
      };

      database = {
        POSTGRES_DB = "app_db";
        POSTGRES_USER = "app_user";
        POSTGRES_PASSWORD = "example_db_password";
        MYSQL_ROOT_PASSWORD = "example_mysql_root_password";
      };

      monitoring = {
        GRAFANA_ADMIN_PASSWORD = "example_grafana_admin_password";
        PROMETHEUS_RETENTION = "15d";
        ALERTMANAGER_WEBHOOK_URL = "https://hooks.example.com/webhook";
      };

      backup = {
        BORG_PASSPHRASE = "example_borg_backup_passphrase_123";
        S3_ACCESS_KEY = "example_s3_access_key";
        S3_SECRET_KEY = "example_s3_secret_key";
        S3_BUCKET = "example-backup-bucket";
      };
    };
  };
}
