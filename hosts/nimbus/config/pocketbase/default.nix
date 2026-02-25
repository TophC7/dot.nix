{
  pkgs,
  secrets,
  ...
}:
let
  name = "pocketbase";
  env = secrets.service.pocketbase;
  smtp = secrets.users.admin.smtp;
  tag = "pocketbase:local";

  # Build context — the directory containing the Dockerfile
  # Nix copies this to the store so docker build has a clean context
  buildContext = ./.;
in
{
  virtualisation.oci-stacks.${name} = {
    containers.${name} = {
      image = tag;
      environment = {
        # Superuser auto-creation on first boot
        PB_ADMIN_EMAIL = smtp.user;
        PB_ADMIN_PASSWORD = env.ADMIN_PASSWORD;

        # SMTP for transactional emails (auth confirmations, resets)
        PB_SMTP_HOST = smtp.host;
        PB_SMTP_PORT = toString smtp.port;
        PB_SMTP_USERNAME = smtp.user;
        PB_SMTP_PASSWORD = smtp.password;
        PB_SMTP_FROM = smtp.from;

        # Optional: encryption key for settings (32 chars)
        PB_ENCRYPTION_KEY = env.ENCRYPTION_KEY;
      };
      volumes = [
        "/ryot/pocketbase/pb_data:/pb/pb_data:rw"
        "/ryot/pocketbase/pb_hooks:/pb/pb_hooks:rw"
        "/ryot/pocketbase/pb_migrations:/pb/pb_migrations:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=${name}"
        "--network-alias=${name}"
        "--ulimit=nofile=4096:4096"
      ];
    };

    description = "PocketBase — backend in 1 file";
  };

  # Build the image before the container service starts
  systemd.services."docker-${name}-build" = {
    description = "Build ${name} Docker image";
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "${name}-build" ''
        if docker image inspect ${tag} >/dev/null 2>&1; then
          echo "${tag} already exists, skipping build"
          exit 0
        fi
        echo "Building ${tag}..."
        docker build -t ${tag} ${buildContext}
      '';
    };
  };

  # Wire: container waits for image build
  systemd.services."docker-${name}" = {
    after = [ "docker-${name}-build.service" ];
    requires = [ "docker-${name}-build.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /ryot/pocketbase 0750 1000 ryot -"
    "d /ryot/pocketbase/pb_data 0750 1000 ryot -"
    "d /ryot/pocketbase/pb_hooks 0750 1000 ryot -"
    "d /ryot/pocketbase/pb_migrations 0750 1000 ryot -"
  ];
}
