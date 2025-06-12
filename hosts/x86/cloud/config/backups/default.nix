{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Shared configuration
  logDir = "/var/log/backups";
  backupServices = [
    {
      name = "forgejo";
      title = "Forgejo";
      service = "backup-forgejo.service";
      logPattern = "borg-forgejo-backup-*.log";
    }
    {
      name = "docker_storage";
      title = "Docker Storage";
      service = "backup-docker-storage.service";
      logPattern = "borg-docker-storage-backup-*.log";
    }
    {
      name = "snapraid";
      title = "SnapRAID";
      service = "snapraid-aio.service";
      logPattern = "SnapRAID-*.out";
      logPath = "/var/log/snapraid";
    }
  ];

  # Helper functions
  users = config.secretsSpec.users;
  notify =
    title: message: logFile:
    let
      attachArg = if logFile == "" then "" else "--attach \"file://${logFile}\"";
      appriseUrl = lib.custom.mkAppriseUrl users.admin.smtp "relay@ryot.foo";
    in
    ''
      ${pkgs.apprise}/bin/apprise  -vv -i "markdown" -t "${title}" \
        -b "${message}" \
        ${attachArg} \
        "${appriseUrl}" || true
    '';

  findLatestLog = pattern: path: ''
    find "${path}" -name "${pattern}" -type f -printf "%T@ %p\\n" 2>/dev/null \
      | sort -nr | head -1 | cut -d' ' -f2
  '';

  # Generate safe variable name (replace hyphens with underscores)
  safeName = name: lib.replaceStrings [ "-" ] [ "_" ] name;

  # Generate status variable references
  statusVarName = name: "STATUS_${safeName name}";

  # Common script utilities
  scriptPrelude = ''
    set -uo pipefail
    LOG_FILE="${logDir}/backup-chain-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "${logDir}"
    exec > >(tee -a "$LOG_FILE") 2>&1

    log() {
      echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"
    }

    # Initialize all status variables
    ${lib.concatMapStringsSep "\n" (s: "${statusVarName s.name}=1") backupServices}
  '';

  # Service runner template
  runService =
    {
      name,
      title,
      service,
      logPattern,
      logPath ? "/tmp",
    }:
    ''
      log "Starting ${title} maintenance..."
      systemctl start ${service} || true
      ${statusVarName name}=$?
      log "${title} completed with status $${statusVarName name}"

      SERVICE_LOG=$(${findLatestLog logPattern logPath})
      if [ -n "$SERVICE_LOG" ]; then
        log "Appending ${title} log: $SERVICE_LOG"
        echo -e "\n\n===== ${title} LOG ($(basename "$SERVICE_LOG")) =====\n" >> "$LOG_FILE"
        cat "$SERVICE_LOG" >> "$LOG_FILE"
        
        # Add SnapRAID-specific summary
        if [ "${name}" = "snapraid" ]; then
          echo -e "\n=== SnapRAID Summary ===" >> "$LOG_FILE"
          grep -E '(Scrub|Sync|Diff|smart)' "$SERVICE_LOG" | tail -n 10 >> "$LOG_FILE"
        fi
      fi
    '';

  # Build the service execution script
  serviceExecution = lib.concatMapStrings runService backupServices;

  # Generate status summary lines
  statusSummaryLines = lib.concatMapStringsSep "\n" (
    s:
    let
      varName = statusVarName s.name;
    in
    "- **${s.title}:** \$([ \$${varName} -eq 0 ] && echo '✅ Success' || echo '❌ Failed') (Exit: \$${varName})"
  ) backupServices;

  # Notification logic with cleaner formatting
  notificationLogic =
    let
      statusVars = map (s: statusVarName s.name) backupServices;
      statusChecks = lib.concatMapStringsSep "\n" (var: "[ \$${var} -eq 0 ] && ") statusVars;
    in
    ''
      # Calculate overall status
      OVERALL_STATUS=0
      ${lib.concatMapStringsSep "\n" (var: "if [ \$${var} -ne 0 ]; then OVERALL_STATUS=1; fi") statusVars}

      TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
      HOSTNAME=$(hostname)

      SUMMARY=$(cat << EOF
      # Backup Chain Complete

      **Host:** $HOSTNAME  
      **Timestamp:** $TIMESTAMP  
      **Overall Status:** $([ $OVERALL_STATUS -eq 0 ] && echo '✅ Success' || echo '⚠️ Failure')

      ## Service Status:
      ${statusSummaryLines}

      **Log Path:** $LOG_FILE
      EOF)

      if [ $OVERALL_STATUS -eq 0 ]; then
        ${notify "✅ Backup Success" "$SUMMARY" "$LOG_FILE"}
      else
        ${notify "⚠️ Backup Issues" "$SUMMARY" "$LOG_FILE"}
      fi

      exit $OVERALL_STATUS
    '';

in
{
  imports = lib.custom.scanPaths ./.;

  systemd.services.backup-chain = {
    description = "Orchestrated Backup Chain";
    path = with pkgs; [
      apprise
      coreutils
      findutils
      gawk
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
      ${scriptPrelude}
      log "Initializing backup chain on $(hostname)"

      ${serviceExecution}

      log "Finalizing backup chain"
      ${notificationLogic}
    '';
  };

  systemd.timers.backup-chain = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
  };

  environment.systemPackages = [ pkgs.apprise ];
  systemd.tmpfiles.rules = [ "d ${logDir} 0755 root root -" ];
}
