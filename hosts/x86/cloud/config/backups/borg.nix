{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Common repositories
  dockerStorageRepo = "/pool/Backups/DockerStorage";
  forgejoRepo = "/pool/Backups/forgejo";

  # Shared environment setup
  borgCommonSettings = ''
    # Don't use cache to avoid issues with concurrent backups
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
    export BORG_NON_INTERACTIVE=yes
  '';

  # Common packages needed for backups
  commonBorgPath = with pkgs; [
    borgbackup
    coreutils
    apprise
    gnugrep
    hostname
    util-linux
    gawk
  ];

  # Repository initialization
  initRepo = repo: ''
    if [ ! -d "${repo}" ]; then
      mkdir -p "${repo}"
      ${pkgs.borgbackup}/bin/borg init --encryption=none "${repo}"
    fi
  '';

  # Notification system
  apprise-url = config.secretsSpec.users.admin.smtp.notifyUrl;
  sendNotification = title: message: ''
    ${pkgs.apprise}/bin/apprise -t "${title}" -b "${message}" "${apprise-url}" || true
  '';

  # Statistics generation
  extractBorgStats = logFile: repoPath: ''
    {
      echo -e "\n==== BACKUP SUMMARY ====\n"
      grep -A10 "Archive name:" ${logFile} || echo "No archive stats found"
      echo -e "\n=== Compression ===\n"
      grep "Compressed size:" ${logFile} || echo "No compression stats found"
      echo -e "\n=== Duration ===\n"
      grep "Duration:" ${logFile} || echo "No duration stats found"
      grep "Throughput:" ${logFile} || echo "No throughput stats found"
      echo -e "\n=== Repository ===\n"
      ${pkgs.borgbackup}/bin/borg info ${repoPath} --last 1 2>/dev/null || echo "Could not get repository info"
      echo -e "\n=== Storage Space ===\n"
      df -h ${repoPath} | grep -v "Filesystem" || echo "Could not get storage info"
    } > ${logFile}.stats
    STATS=$(cat ${logFile}.stats || echo "No stats available")
  '';

  # Unified backup service generator with optional features
  mkBorgBackupService =
    {
      name,
      title,
      repo,
      sourcePath,
      keepDaily,
      keepWeekly,
      keepMonthly,
      schedule ? null,
      enableNotifications ? true,
      verbose ? false,
    }:
    let
      maybeCreateTimer = lib.optionalAttrs (schedule != null) {
        timers."backup-${name}" = {
          description = "Timer for ${title} Backup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = schedule;
            Persistent = true;
            RandomizedDelaySec = "5min";
          };
        };
      };

      logPrefix = if verbose then "set -x;" else "";
    in
    {
      services."backup-${name}" = {
        description = "Backup ${title} with Borg";
        inherit (commonServiceConfig) path serviceConfig;

        script = ''
          ${borgCommonSettings}
          ${logPrefix}  # Add verbose logging if enabled

          LOG_FILE="/tmp/borg-${name}-backup-$(date +%Y%m%d-%H%M%S).log"
          ${initRepo repo}

          echo "Starting ${title} backup at $(date)" > $LOG_FILE
          ARCHIVE_NAME="${name}-$(date +%Y-%m-%d_%H%M%S)"
          START_TIME=$(date +%s)

          # Add verbose output redirection if enabled
          ${if verbose then "exec 3>&1 4>&2" else ""}
          ${pkgs.borgbackup}/bin/borg create \
            --stats \
            --compression zstd,15 \
            --exclude '*.tmp' \
            --exclude '*/tmp/*' \
            ${repo}::$ARCHIVE_NAME \
            ${sourcePath} >> $LOG_FILE 2>&1 ${if verbose then "| tee /dev/fd/3" else ""}

          BACKUP_STATUS=$?
          END_TIME=$(date +%s)
          DURATION=$((END_TIME - START_TIME))
          echo "Total time: $DURATION seconds ($(date -d@$DURATION -u +%H:%M:%S))" >> $LOG_FILE

          ${extractBorgStats "$LOG_FILE" "${repo}"}

          echo -e "\nPruning old backups..." >> $LOG_FILE
          ${pkgs.borgbackup}/bin/borg prune \
            --keep-daily ${toString keepDaily} \
            --keep-weekly ${toString keepWeekly} \
            --keep-monthly ${toString keepMonthly} \
            ${repo} >> $LOG_FILE 2>&1 ${if verbose then "| tee /dev/fd/3" else ""}

          PRUNE_STATUS=$?

          echo -e "\nRemaining archives after pruning:" >> $LOG_FILE
          ${pkgs.borgbackup}/bin/borg list ${repo} >> $LOG_FILE 2>&1 || true

          ${
            if enableNotifications then
              ''
                if [ $BACKUP_STATUS -eq 0 ] && [ $PRUNE_STATUS -eq 0 ]; then
                  ${sendNotification "✅ ${title} Backup Complete" "${title} backup completed successfully on $(hostname) at $(date)\nDuration: $(date -d@$DURATION -u +%H:%M:%S)\n\n$STATS"}
                else
                  ${sendNotification "❌ ${title} Backup Failed" "${title} backup failed on $(hostname) at $(date)\n\nBackup Status: $BACKUP_STATUS\nPrune Status: $PRUNE_STATUS\n\nPartial Stats:\n$STATS\n\nSee $LOG_FILE for details"}
                fi
              ''
            else
              "echo 'Notifications disabled' >> $LOG_FILE"
          }

          rm -f $LOG_FILE.stats
          exit $BACKUP_STATUS
        '';
      };

    }
    // maybeCreateTimer;

  # Common service configuration
  commonServiceConfig = {
    path = commonBorgPath;
    serviceConfig = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

in
{
  environment.systemPackages = with pkgs; [
    borgbackup
  ];

  systemd = lib.mkMerge [
    (mkBorgBackupService {
      name = "docker-storage";
      title = "Docker Storage";
      repo = dockerStorageRepo;
      sourcePath = "/mnt/drive1/DockerStorage";
      # INFO: This shit confusing but basically
      # keeps the last 7 days,
      # then keeps AT LEAST ONE for last 4 weeks
      # and finally AT LEAST ONE for the last 3 months
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 3;
      # No schedule = no timer created
      # schedule = "*-*-* 03:00:00";
      enableNotifications = false;
      verbose = true;
    })

    (mkBorgBackupService {
      name = "forgejo";
      title = "Forgejo";
      repo = forgejoRepo;
      sourcePath = "/pool/forgejo";
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 3;
      # schedule = "*-*-* 03:00:00";
      enableNotifications = false;
      verbose = true;
    })
  ];
}
