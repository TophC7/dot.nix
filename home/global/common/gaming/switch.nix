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

  # Wrapper script that launches emulator directly with backup management
  mkEmulatorWrapper =
    {
      name,
      emulatorCmd,
      savePath,
      backupPath,
      env ? { }, # Optional environment variables
      ...
    }:
    let
      # Convert env attrset to Fish export statements
      envExports = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (key: value: "  set -gx ${key} '${toString value}'") env
      );
    in
    pkgs.writeScript "launch-${lib.toLower name}" ''
      #!${lib.getExe pkgs.fish}

      # Set environment variables
      ${envExports}

      # Cleanup function to stop services on exit
      function cleanup --on-event fish_exit
        echo "[${name}] Stopping backup timer..."
        ${pkgs.systemd}/bin/systemctl --user stop emulator-${lib.toLower name}-backup.timer 2>/dev/null; or true

        # Final backup on exit
        echo "[${name}] Creating final backup..."
        ${backupScript} stop '${savePath}' '${backupPath}'
      end

      # Initial backup before starting
      echo "[${name}] Creating initial backup..."
      ${backupScript} start '${savePath}' '${backupPath}'

      # Start the backup timer
      echo "[${name}] Starting backup timer..."
      ${pkgs.systemd}/bin/systemctl --user start emulator-${lib.toLower name}-backup.timer

      # Run the emulator in the foreground
      echo "[${name}] Launching emulator..."
      exec ${emulatorCmd}
    '';

  # One-shot service for timer-triggered backups
  mkBackupService = name: savePath: backupPath: {
    "emulator-${lib.toLower name}-backup" = {
      Unit = {
        Description = "Backup ${name} saves";
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
      };

      Timer = {
        OnActiveSec = "5min";
        OnUnitActiveSec = "5min";
        Unit = "emulator-${lib.toLower name}-backup.service";
      };
    };
  };

  # Desktop entry that launches wrapper script directly
  mkEmulatorDesktopEntry =
    {
      name,
      wrapperScript,
      icon ? "applications-games",
      wmClass ? name,
      ...
    }@args:
    {
      name = "${name} (Protected)";
      comment = "${name} with automatic save backups";
      exec = "${wrapperScript}";
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
    env = {
      DXVK_FRAME_RATE = "60";
    };
  };

  # Configuration for Eden emulator
  edenConfig = {
    name = "Eden";
    emulatorCmd = "${lib.getExe pkgs.eden}";
    savePath = "~/.local/share/eden/nand/user/save";
    backupPath = "~/.switch/EdenBackups";
    icon = "Eden";
    wmClass = "Eden";
    env = {
      DXVK_FRAME_RATE = "60";
    };
  };

  # Create wrapper scripts for each emulator
  ryubingWrapper = mkEmulatorWrapper ryubingConfig;

  edenWrapper = mkEmulatorWrapper edenConfig;
in
{
  home.packages = with pkgs; [
    borgbackup
    nsz
    ryubing
    eden
  ];

  # Systemd user services (only backup services, not main emulator services)
  systemd.user.services = lib.mkMerge [
    (mkBackupService ryubingConfig.name ryubingConfig.savePath ryubingConfig.backupPath)
    (mkBackupService edenConfig.name edenConfig.savePath edenConfig.backupPath)
  ];

  # Systemd user timers
  systemd.user.timers = lib.mkMerge [
    (mkBackupTimer ryubingConfig.name)
    (mkBackupTimer edenConfig.name)
  ];

  # Desktop entries
  xdg.desktopEntries = {
    ryubing = mkEmulatorDesktopEntry (ryubingConfig // { wrapperScript = ryubingWrapper; });
    eden = mkEmulatorDesktopEntry (edenConfig // { wrapperScript = edenWrapper; });
  };
}
