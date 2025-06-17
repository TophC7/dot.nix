{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.backup;

  # Helper functions
  safeName = name: replaceStrings [ "-" ] [ "_" ] name;
  statusVar = name: "STATUS_${safeName name}";
  findLatestLog = pattern: path: ''
    find "${path}" -name "${pattern}" -type f -printf "%T@ %p\\n" 2>/dev/null \
      | sort -nr | head -1 | cut -d' ' -f2
  '';

  # Borg service generator
  mkBorgService =
    job:
    let
      borgCommon = ''
        export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
        export BORG_NON_INTERACTIVE=yes
      '';

      initRepo = ''
        if [ ! -d "${job.repo}" ]; then
          mkdir -p "${job.repo}"
          ${pkgs.borgbackup}/bin/borg init --encryption=none "${job.repo}"
        fi
      '';

      extractStats = ''
        {
          echo -e "\n==== BACKUP SUMMARY ====\n"
          grep -A10 "Archive name:" $LOG_FILE || echo "No archive stats found"
          echo -e "\n=== Compression ===\n"
          grep "Compressed size:" $LOG_FILE || echo "No compression stats found"
          echo -e "\n=== Duration ===\n"
          grep "Duration:" $LOG_FILE || echo "No duration stats found"
          grep "Throughput:" $LOG_FILE || echo "No throughput stats found"
          echo -e "\n=== Repository ===\n"
          ${pkgs.borgbackup}/bin/borg info ${job.repo} --last 1 2>/dev/null || echo "Could not get repository info"
          echo -e "\n=== Storage Space ===\n"
          df -h ${job.repo} | grep -v "Filesystem" || echo "Could not get storage info"
        } > $LOG_FILE.stats
        STATS=$(cat $LOG_FILE.stats || echo "No stats available")
      '';

      excludeArgs = concatMapStringsSep " " (pattern: "--exclude '${pattern}'") job.excludePatterns;
    in
    {
      services."backup-${job.name}" = {
        description = "Backup ${job.title} with Borg";
        path = with pkgs; [
          borgbackup
          coreutils
          gnugrep
          hostname
          util-linux
          gawk
        ];
        serviceConfig = {
          Type = "oneshot";
          IOSchedulingClass = "idle";
          CPUSchedulingPolicy = "idle";
          Nice = 19;
        };

        script = ''
          ${borgCommon}
          ${optionalString job.verbose "set -x"}

          LOG_FILE="/tmp/borg-${job.name}-backup-$(date +%Y%m%d-%H%M%S).log"
          ${initRepo}

          echo "Starting ${job.title} backup at $(date)" > $LOG_FILE
          START_TIME=$(date +%s)

          ${pkgs.borgbackup}/bin/borg create \
            --stats \
            --compression ${job.compression} \
            ${excludeArgs} \
            ${job.repo}::${job.name}-$(date +%Y-%m-%d_%H%M%S) \
            ${job.sourcePath} >> $LOG_FILE 2>&1

          BACKUP_STATUS=$?
          echo "Total time: $(($(date +%s) - START_TIME)) seconds" >> $LOG_FILE
          ${extractStats}

          echo -e "\nPruning old backups..." >> $LOG_FILE
          ${pkgs.borgbackup}/bin/borg prune \
            --keep-daily ${toString job.keepDaily} \
            --keep-weekly ${toString job.keepWeekly} \
            --keep-monthly ${toString job.keepMonthly} \
            ${job.repo} >> $LOG_FILE 2>&1

          PRUNE_STATUS=$?

          rm -f $LOG_FILE.stats
          exit $BACKUP_STATUS
        '';
      };
    }
    // optionalAttrs (job.schedule != null) {
      timers."backup-${job.name}" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = job.schedule;
          Persistent = true;
          RandomizedDelaySec = "5min";
        };
      };
    };

  # Orchestration service
  mkChainService =
    let
      allJobs = cfg.jobs ++ cfg.maintenanceJobs;
      initVars = concatMapStringsSep "\n" (j: "${statusVar j.name}=1") allJobs;

      runJob = job: ''
        # Determine log pattern
        LOG_PATTERN="${if job.logPattern != "" then job.logPattern else "borg-${job.name}-backup-*.log"}"

        log "Starting ${job.title}..."

        systemctl start ${if job ? service then job.service else "backup-${job.name}"} || true

        # Wait for service to complete and get its exit status
        while systemctl is-active ${
          if job ? service then job.service else "backup-${job.name}"
        } >/dev/null 2>&1; do
          sleep 5
        done

        # Get the actual service exit status
        ${statusVar job.name}=$(systemctl show ${
          if job ? service then job.service else "backup-${job.name}"
        } --property=ExecMainStatus --value)
        log "${job.title} completed with status $${statusVar job.name}"

        # Give logs time to be written
        sleep 2

        SERVICE_LOG=$(${findLatestLog "$LOG_PATTERN" "${job.logPath}"})
        if [ -n "$SERVICE_LOG" ] && [ -r "$SERVICE_LOG" ]; then
          log "Appending ${job.title} log: $SERVICE_LOG"
          echo -e "\n\n===== ${job.title} LOG =====\n" >> "$LOG_FILE"
          cat "$SERVICE_LOG" >> "$LOG_FILE" 2>/dev/null || echo "Could not read log file" >> "$LOG_FILE"
        else
          log "No readable log found for ${job.title} (pattern: $LOG_PATTERN in ${job.logPath})"
        fi
      '';
    in
    {
      services.backup-chain = {
        description = "Backup Orchestration Chain";
        path = with pkgs; [
          apprise
          coreutils
          findutils
          gnugrep
          hostname
          systemd
          util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
          Nice = 19;
          IOSchedulingClass = "idle";
          CPUSchedulingPolicy = "idle";
        };

        script = ''
            set -uo pipefail
            LOG_FILE="${cfg.logDir}/backup-chain-$(date +%Y%m%d-%H%M%S).log"
            mkdir -p "${cfg.logDir}"
            exec > >(tee -a "$LOG_FILE") 2>&1

            log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

            # Initialize status tracking
            declare -A JOB_STATUS
            ${concatMapStrings (j: "JOB_STATUS['${j.name}']=1\n") allJobs}

            log "Starting backup chain on $(hostname)"

            ${concatMapStrings (job: ''
              log "Starting ${job.title}..."
              systemctl start ${if job ? service then job.service else "backup-${job.name}"} || true

              # Wait for completion
              while systemctl is-active ${
                if job ? service then job.service else "backup-${job.name}"
              } >/dev/null 2>&1; do
                sleep 5
              done

              # Capture exit status
              JOB_STATUS['${job.name}']=$(systemctl show ${
                if job ? service then job.service else "backup-${job.name}"
              } --property=ExecMainStatus --value)
              log "${job.title} completed with status ''${JOB_STATUS['${job.name}']}"

              # Give logs time to be written
              sleep 2

              # Find and append logs
              LOG_PATTERN="${if job.logPattern != "" then job.logPattern else "borg-${job.name}-backup-*.log"}"
              SERVICE_LOG=$(${findLatestLog "$LOG_PATTERN" "${job.logPath}"})
              if [ -n "$SERVICE_LOG" ] && [ -r "$SERVICE_LOG" ]; then
                log "Appending ${job.title} log: $SERVICE_LOG"
                echo -e "\n\n===== ${job.title} LOG =====\n" >> "$LOG_FILE"
                cat "$SERVICE_LOG" >> "$LOG_FILE" 2>/dev/null || echo "Could not read log file" >> "$LOG_FILE"
              else
                log "No readable log found for ${job.title} (pattern: $LOG_PATTERN in ${job.logPath})"
              fi
            '') allJobs}

            # Calculate overall status
            OVERALL_STATUS=0
            for status in "''${JOB_STATUS[@]}"; do
              if [ "$status" -ne 0 ]; then
                OVERALL_STATUS=1
                break
              fi
            done

            # Build summary
            HOSTNAME=$(hostname)
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            
            # Build job status lines
            JOB_LINES=""
            ${concatMapStrings (job: ''
                  if [ ''${JOB_STATUS['${job.name}']} -eq 0 ]; then
                    STATUS_ICON="✅"
                  else
                    STATUS_ICON="❌"
                  fi
                  JOB_LINES="$JOB_LINES- **${job.title}:** $STATUS_ICON (Exit: ''${JOB_STATUS['${job.name}']})
              "
            '') allJobs}

            # Create the final summary
            SUMMARY="# Backup Chain Complete

          **Host:** $HOSTNAME
          **Timestamp:** $TIMESTAMP
          **Overall Status:** $([ $OVERALL_STATUS -eq 0 ] && echo '✅ Success' || echo '⚠️ Failure')

          ## Job Status:
          $JOB_LINES
          **Log Path:** $LOG_FILE"

            # Send notification
            ${pkgs.apprise}/bin/apprise -vv -i "markdown" \
              -t "Backup $([ $OVERALL_STATUS -eq 0 ] && echo '✅' || echo '⚠️')" \
              -b "$SUMMARY" \
              --attach "file://$LOG_FILE" \
              "${cfg.notificationUrl}" || true

            exit $OVERALL_STATUS
        '';
      };

      timers.backup-chain = mkIf cfg.enableChainTimer {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.chainSchedule;
          Persistent = true;
          RandomizedDelaySec = "5min";
        };
      };
    };

  # Job types
  borgJobType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Unique service name";
      };
      title = mkOption {
        type = types.str;
        description = "Human-readable title";
      };
      repo = mkOption {
        type = types.str;
        description = "Borg repository path";
      };
      sourcePath = mkOption {
        type = types.str;
        description = "Path to back up";
      };
      schedule = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Timer schedule for standalone execution";
      };
      keepDaily = mkOption {
        type = types.int;
        default = 7;
      };
      keepWeekly = mkOption {
        type = types.int;
        default = 4;
      };
      keepMonthly = mkOption {
        type = types.int;
        default = 3;
      };
      verbose = mkOption {
        type = types.bool;
        default = false;
      };
      compression = mkOption {
        type = types.str;
        default = "zstd,15";
      };
      excludePatterns = mkOption {
        type = types.listOf types.str;
        default = [
          "*.tmp"
          "*/tmp/*"
        ];
      };
      logPattern = mkOption {
        type = types.str;
        default = "";
        description = "Log pattern for chain to find";
      };
      logPath = mkOption {
        type = types.str;
        default = "/tmp";
        description = "Path to search for logs";
      };
    };
  };

  maintenanceJobType = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      title = mkOption { type = types.str; };
      service = mkOption {
        type = types.str;
        description = "Systemd service to run";
      };
      logPattern = mkOption { type = types.str; };
      logPath = mkOption {
        type = types.str;
        default = "/tmp";
      };
    };
  };

in
{
  options.services.backup = {
    enable = mkEnableOption "backup system";
    notificationUrl = mkOption { type = types.str; };
    logDir = mkOption {
      type = types.str;
      default = "/var/log/backups";
    };
    jobs = mkOption {
      type = types.listOf borgJobType;
      default = [ ];
    };
    maintenanceJobs = mkOption {
      type = types.listOf maintenanceJobType;
      default = [ ];
    };
    enableChainTimer = mkOption {
      type = types.bool;
      default = false;
    };
    chainSchedule = mkOption {
      type = types.str;
      default = "*-*-* 03:00:00";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      borgbackup
      apprise
    ];

    systemd = mkMerge [
      # Create log directory
      { tmpfiles.rules = [ "d ${cfg.logDir} 0755 root root -" ]; }

      # Individual backup services
      (mkMerge (map mkBorgService cfg.jobs))

      # Backup chain orchestration
      (mkIf (cfg.jobs != [ ] || cfg.maintenanceJobs != [ ]) mkChainService)
    ];
  };
}
