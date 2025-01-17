# Configuration for Gitea instance

{
  config,
  pkgs,
  admin,
  ...
}:
{
  # Forgejo configuration
  services.forgejo = {
    enable = true;

    stateDir = "/pool/forgejo";

    # Settings
    dump = {
      # :D idk what this does
      enable = false;
      interval = "weekly";
    };

    settings = {
      DEFAULT = {
        # Configuration for Gitea
        APP_NAME = "Ryot Git";
        RUN_MODE = "dev";
      };

      server = {
        # Configuration for reverse proxy
        ROOT_URL = "https://git.ryot.foo/";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3003;
        DOMAIN = "localhost";
      };

      repository = {
        DEFAULT_PRIVATE = true;
      };

      ui = {
        DEFAULT_THEME = "forgejo-dark";
        SHOW_USER_EMAIL = false;
      };

      "ui.meta" = {
        AUTHOR = "Ryot";
        DESCRIPTION = "Ryot Gitea instance";
        KEYWORDS = "";
      };

      security = {
        INSTALL_LOCK = true;
      };

      session = {
        SESSION_LIFE_TIME = 86400 * 7; # 1 week
      };

      picture = {
        DISABLE_GRAVATAR = true;
      };

      "cron.sync_external_users".ENABLED = false;

      log.LEVEL = "Info";
      # Private server
      service.DISABLE_REGISTRATION = false;
      # Disable package manager functionality
      packages.ENABLED = false;

    };
  };

  users.users.forgejo.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClZstYoT64zHnGfE7LMYNiQPN5/gmCt382lC+Ji8lrH PVE"
  ];

  # Give admin group access to forgejo config
  users.users.${admin}.extraGroups = [ "forgejo" ];
}
