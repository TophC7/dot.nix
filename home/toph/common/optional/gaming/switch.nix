# switch.nix
{
  pkgs,
  config,
  lib,
  ...
}:

let
  citron-emu = pkgs.callPackage (lib.custom.relativeToRoot "pkgs/common/citron-emu/package.nix") {
    inherit pkgs;
  };
  borgtui = pkgs.callPackage (lib.custom.relativeToRoot "pkgs/common/borgtui/package.nix") {
    inherit pkgs;
  };

  user = config.hostSpec.username;

  borg-wrapper = pkgs.writeScript "borg-wrapper" ''
    #!${lib.getExe pkgs.fish}

    # Enable strict error handling
    set -e

    # Parse arguments
    set -l CMD

    while test (count $argv) -gt 0
        switch $argv[1]
            case -p --path
                set BACKUP_PATH $argv[2]
                set -e argv[1..2]
            case -o --output
                set BORG_REPO $argv[2]
                set -e argv[1..2]
            case -m --max
                set MAX_BACKUPS $argv[2]
                set -e argv[1..2]
            case --
                set -e argv[1]
                set CMD $argv
                set -e argv[1..-1]
                break
            case '*'
                echo "Unknown option: $argv[1]"
                exit 1
        end
    end

    # Initialize Borg repository
    mkdir -p "$BORG_REPO"
    if not ${pkgs.borgbackup}/bin/borg list "$BORG_REPO" &>/dev/null
        echo "Initializing new Borg repository at $BORG_REPO"
        ${pkgs.borgbackup}/bin/borg init --encryption=none "$BORG_REPO"
    end

    # Backup functions with error suppression
    function create_backup
        set -l tag $argv[1]
        set -l timestamp (date +%Y%m%d-%H%M%S)
        echo "Creating $tag backup: $timestamp"
        ${pkgs.borgbackup}/bin/borg create --stats --compression zstd,15 \
            --files-cache=mtime,size \
            --lock-wait 5 \
            "$BORG_REPO::$tag-$timestamp" "$BACKUP_PATH" || true
    end

    function prune_backups
        echo "Pruning old backups"
        ${pkgs.borgbackup}/bin/borg prune --keep-last "$MAX_BACKUPS" --stats "$BORG_REPO" || true
    end

    # Initial backup
    create_backup "initial"
    prune_backups

    # Start emulator in a subprocess group
    fish -c "
        function on_exit
            exit 0
        end
        
        trap on_exit INT TERM
        exec $CMD
    " &
    set PID (jobs -lp | tail -n1)

    # Cleanup function
    function cleanup
        # Send TERM to process group
        kill -TERM -$PID 2>/dev/null || true
        wait $PID 2>/dev/null || true
        create_backup "final"
        prune_backups
    end

    function on_exit --on-signal INT --on-signal TERM
        cleanup
    end

    # Debounced backup trigger
    set last_backup (date +%s)
    set backup_cooldown 30  # Minimum seconds between backups

    # Watch loop with timeout
    while kill -0 $PID 2>/dev/null
        # Wait for changes with 5-second timeout
        if ${pkgs.inotify-tools}/bin/inotifywait \
            -r \
            -qq \
            -e close_write,delete,moved_to \
            -t 5 \
            "$BACKUP_PATH"
            
            set current_time (date +%s)
            if test (math "$current_time - $last_backup") -ge $backup_cooldown
                create_backup "auto"
                prune_backups
                set last_backup $current_time
            else
              echo "Skipping backup:" + (math "$backup_cooldown - ($current_time - $last_backup)") + "s cooldown remaining"
            end
        end
    end

    cleanup
    exit 0
  '';

  # Generic function to create launcher scripts
  mkLaunchCommand =
    {
      savePath, # Path to the save directory
      backupPath, # Path where backups should be stored
      maxBackups ? 30, # Maximum number of backups to keep
      command, # Command to execute
    }:
    "${borg-wrapper} -p \"${savePath}\" -o \"${backupPath}\" -m ${toString maxBackups} -- ${command}";

in
{
  home.packages = with pkgs; [
    citron-emu
    ryubing
    borgbackup
    borgtui
    inotify-tools
  ];

  xdg.desktopEntries = {
    Ryujinx = {
      name = "Ryujinx w/ Borg Backups";
      comment = "Ryujinx Emulator with Borg Backups";
      exec = mkLaunchCommand {
        savePath = "/home/${user}/.config/Ryujinx/bis/user/save";
        backupPath = "/pool/Backups/Switch/RyubingSaves";
        maxBackups = 30;
        command = "ryujinx";
      };
      icon = "Ryujinx";
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
        StartupWMClass = "Ryujinx";
        GenericName = "Nintendo Switch Emulator";
      };
    };

    citron-emu = {
      name = "Citron w/ Borg Backups";
      comment = "Citron Emulator with Borg Backups";
      exec = mkLaunchCommand {
        savePath = "/home/${user}/.local/share/citron/nand/user/save";
        backupPath = "/pool/Backups/Switch/CitronSaves";
        maxBackups = 30;
        command = "citron-emu";
      };
      icon = "applications-games";
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
        StartupWMClass = "Citron";
        GenericName = "Nintendo Switch Emulator";
      };
    };
  };
}
