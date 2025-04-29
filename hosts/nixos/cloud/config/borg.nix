{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Borg backup destinations
  dockerStorageRepo = "/pool/Backups/DockerStorage";
  forgejoRepo = "/pool/Backups/forgejo";

  # Common borg backup settings
  borgCommonSettings = ''
    # Don't use cache to avoid issues with concurrent backups
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

    # Set this for non-interactive use
    export BORG_NON_INTERACTIVE=yes
  '';

  # Initialize a repo if it doesn't exist
  initRepo = repo: ''
    if [ ! -d "${repo}" ]; then
      mkdir -p "${repo}"
      ${pkgs.borgbackup}/bin/borg init --encryption=none "${repo}"
    fi
  '';

in
{
  # Make sure borg is installed
  environment.systemPackages = [ pkgs.borgbackup ];

  # Docker Storage Backup Service
  systemd.services.backup-docker-storage = {
    description = "Backup Docker storage directory with Borg";

    path = with pkgs; [
      borgbackup
      coreutils
    ];

    script = ''
      ${borgCommonSettings}

      # Initialize repository if needed
      ${initRepo dockerStorageRepo}

      # Create backup
      ${pkgs.borgbackup}/bin/borg create \
        --stats \
        --compression zstd,15 \
        --exclude '*.tmp' \
        --exclude '*/tmp/*' \
        ${dockerStorageRepo}::docker-{now:%Y-%m-%d_%H%M%S} \
        /mnt/drive1/DockerStorage
        
      # Prune old backups
      ${pkgs.borgbackup}/bin/borg prune \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 3 \
        ${dockerStorageRepo}
    '';

    serviceConfig = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  # Docker Storage Backup Timer (Weekly on Monday at 4am)
  systemd.timers.backup-docker-storage = {
    description = "Timer for Docker Storage Backup";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "Mon *-*-* 04:00:00";
      Persistent = true; # Run backup if system was off during scheduled time
      RandomizedDelaySec = "5min"; # Add randomized delay
    };
  };

  # Forgejo Backup Service
  systemd.services.backup-forgejo = {
    description = "Backup Forgejo directory with Borg";

    path = with pkgs; [
      borgbackup
      coreutils
    ];

    script = ''
      ${borgCommonSettings}

      # Initialize repository if needed
      ${initRepo forgejoRepo}

      # Create backup
      ${pkgs.borgbackup}/bin/borg create \
        --stats \
        --compression zstd,15 \
        --exclude '*.tmp' \
        --exclude '*/tmp/*' \
        ${forgejoRepo}::forgejo-{now:%Y-%m-%d_%H%M%S} \
        /pool/forgejo
        
      # Prune old backups
      ${pkgs.borgbackup}/bin/borg prune \
        --keep-daily 14 \
        --keep-weekly 4 \
        --keep-monthly 3 \
        ${forgejoRepo}
    '';

    serviceConfig = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  # Forgejo Backup Timer (Every 2 days at 4am)
  systemd.timers.backup-forgejo = {
    description = "Timer for Forgejo Backup";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-1/2 04:00:00"; # Every 2 days at 4am
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
  };
}
