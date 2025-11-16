# switch.nix - Systemd-based backup service for Switch emulators
{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Backup script that systemd services will call
  backupScript = pkgs.writeShellScript "switch-backup" ''
    set -euo pipefail

    LABEL="$1"
    SAVE_PATH="$2"
    BACKUP_PATH="$3"

    # Expand tilde if present
    SAVE_PATH="$(eval echo "$SAVE_PATH")"
    BACKUP_PATH="$(eval echo "$BACKUP_PATH")"

    # Initialize Borg repo if needed
    mkdir -p "$BACKUP_PATH"
    if ! ${pkgs.borgbackup}/bin/borg list "$BACKUP_PATH" &>/dev/null; then
        ${pkgs.borgbackup}/bin/borg init --encryption=none "$BACKUP_PATH"
    fi

    # Create backup
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    echo "[Backup] Creating $LABEL-$TIMESTAMP"

    cd "$(dirname "$SAVE_PATH")"
    ${pkgs.borgbackup}/bin/borg create \
        --compression zstd,15 \
        "$BACKUP_PATH::$LABEL-$TIMESTAMP" \
        "$(basename "$SAVE_PATH")" 2>&1 | grep "This archive" || true

    # Prune old backups
    ${pkgs.borgbackup}/bin/borg prune --keep-last 50 "$BACKUP_PATH" 2>/dev/null
  '';

  # Main emulator service
  mkEmulatorService = name: emulatorCmd: savePath: backupPath: {
    "emulator-${lib.toLower name}" = {
      Unit = {
        Description = "${name} emulator with automatic save backups";
        After = [ "graphical-session.target" ];
        # Ensure timer starts/stops with service
        Wants = [ "emulator-${lib.toLower name}-backup.timer" ];
      };

      Service = {
        Type = "simple";

        # Backup on start
        ExecStartPre = "${backupScript} start '${savePath}' '${backupPath}'";

        # Run emulator
        ExecStart = emulatorCmd;

        # Start timer for periodic backups
        ExecStartPost = "${pkgs.systemd}/bin/systemctl --user start emulator-${lib.toLower name}-backup.timer";

        # Stop timer and backup on stop
        ExecStopPost = [
          "${pkgs.systemd}/bin/systemctl --user stop emulator-${lib.toLower name}-backup.timer"
          "${pkgs.bash}/bin/bash -c 'sleep 3; ${backupScript} stop \"${savePath}\" \"${backupPath}\"'"
        ];

        # Restart policy
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  # One-shot service for timer-triggered backups
  mkBackupService = name: savePath: backupPath: {
    "emulator-${lib.toLower name}-backup" = {
      Unit = {
        Description = "Backup ${name} saves";
        # Only run when emulator service is active
        Requisite = [ "emulator-${lib.toLower name}.service" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${backupScript} interval '${savePath}' '${backupPath}'";
      };
    };
  };

  # Timer for periodic backups
  mkBackupTimer = name: {
    "emulator-${lib.toLower name}-backup" = {
      Unit = {
        Description = "Periodic backup timer for ${name} saves";
        # Timer is controlled by the emulator service
        PartOf = [ "emulator-${lib.toLower name}.service" ];
      };

      Timer = {
        OnActiveSec = "5min";
        OnUnitActiveSec = "5min";
        Unit = "emulator-${lib.toLower name}-backup.service";
      };

      # No Install section - timer is started/stopped by the emulator service
    };
  };

  # Desktop entry that starts the systemd service
  mkEmulatorDesktopEntry =
    {
      name,
      icon ? "applications-games",
      wmClass ? name,
      ...
    }@args:
    {
      name = "${name} (Protected)";
      comment = "${name} with automatic save backups";
      exec = "systemctl --user start emulator-${lib.toLower name}.service";
      icon = icon;
      type = "Application";
      terminal = false;
      categories = [
        "Game"
        "Emulator"
      ];
      mimeType = [
        "application/x-nx-nca"
        "application/x-nx-nro"
        "application/x-nx-nso"
        "application/x-nx-nsp"
        "application/x-nx-xci"
      ];
      prefersNonDefaultGPU = true;
      settings = {
        StartupWMClass = wmClass;
        GenericName = "Nintendo Switch Emulator";
      }
      // (args.settings or { });
    };

  gamescorperun = lib.getExe config.play.gamescoperun.package;

  # Configuration for Ryubing emulator
  ryubingConfig = {
    name = "Ryubing";
    emulatorCmd = "${gamescorperun} ${lib.getExe pkgs.ryubing}";
    savePath = "~/.config/Ryujinx/bis/user/save";
    backupPath = "~/.switch/RyubingBackups";
    icon = "Ryujinx";
    wmClass = "Ryubing";
  };
in
{
  home.packages = with pkgs; [
    borgbackup
    nsz
    ryubing
  ];

  # Systemd user services
  systemd.user.services = lib.mkMerge [
    (mkEmulatorService ryubingConfig.name ryubingConfig.emulatorCmd ryubingConfig.savePath
      ryubingConfig.backupPath
    )
    (mkBackupService ryubingConfig.name ryubingConfig.savePath ryubingConfig.backupPath)
  ];

  # Systemd user timers
  systemd.user.timers = mkBackupTimer ryubingConfig.name;

  # Desktop entries
  xdg.desktopEntries = {
    ryubing = mkEmulatorDesktopEntry ryubingConfig;
  };

  # Service management aliases
  home.shellAliases = {
    # Start/stop emulator
    start-ryubing = "systemctl --user start emulator-ryubing.service";
    stop-ryubing = "systemctl --user stop emulator-ryubing.service";
    status-ryubing = "systemctl --user status emulator-ryubing.service emulator-ryubing-backup.timer";
    # View logs
    ryubing-logs = "journalctl --user -u emulator-ryubing.service -u emulator-ryubing-backup.service -n 50";
  };
}
