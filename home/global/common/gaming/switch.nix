# switch.nix
{
  pkgs,
  config,
  lib,
  hostSpec,
  ...
}:

let
  homeDir = hostSpec.home;

  borg-wrapper = pkgs.writeScript "borg-wrapper" ''
    #!${lib.getExe pkgs.fish}

    # Parse arguments using argparse
    function parse_args
        argparse 'p/path=' 'o/output=' 'm/max=' 'h/help' -- $argv
        or return 1
        
        if set -ql _flag_help
            echo "Usage: borg-wrapper -p|--path PATH -o|--output REPO -m|--max MAX_BACKUPS -- COMMAND..."
            echo "  -p, --path PATH       Path to backup"
            echo "  -o, --output REPO     Path to store backups"
            echo "  -m, --max MAX         Maximum number of backups to keep"
            echo "  -h, --help            Show this help"
            exit 0
        end
        
        # Check required arguments
        if not set -ql _flag_path
            echo "Error: --path is required" >&2
            return 1
        end
        if not set -ql _flag_output
            echo "Error: --output is required" >&2
            return 1
        end
        
        # Set defaults
        set -g BACKUP_PATH $_flag_path
        set -g BORG_REPO $_flag_output
        
        if set -ql _flag_max
            set -g MAX_BACKUPS $_flag_max
        else
            set -g MAX_BACKUPS 30
        end
        
        # Everything remaining is the command to execute
        set -g CMD $argv
        
        # Verify we have a command
        if test (count $CMD) -eq 0
            echo "Error: No command specified after --" >&2
            return 1
        end
    end

    # Parse the arguments
    parse_args $argv
    or exit 1

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
        
        # Push to parent directory, backup the basename only, then pop back
        pushd (dirname "$BACKUP_PATH") >/dev/null
        ${pkgs.borgbackup}/bin/borg create --stats --compression zstd,15 \
            --files-cache=mtime,size \
            --lock-wait 5 \
            "$BORG_REPO::$tag-$timestamp" (basename "$BACKUP_PATH") || true
        popd >/dev/null
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
        savePath = "${homeDir}/.config/Ryujinx/bis/user/save";
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

    # FIXME: change to edenemu
    # citron-emu = {
    #   name = "Citron w/ Borg Backups";
    #   comment = "Citron Emulator with Borg Backups";
    #   exec = mkLaunchCommand {
    #     savePath = "${homeDir}/.local/share/citron/nand/user/save";
    #     backupPath = "/pool/Backups/Switch/CitronSaves";
    #     maxBackups = 30;
    #     command = "citron-emu";
    #   };
    #   icon = "applications-games";
    #   type = "Application";
    #   terminal = false;
    #   categories = [
    #     "Game"
    #     "Emulator"
    #   ];
    #   mimeType = [
    #     "application/x-nx-nca"
    #     "application/x-nx-nro"
    #     "application/x-nx-nso"
    #     "application/x-nx-nsp"
    #     "application/x-nx-xci"
    #   ];
    #   prefersNonDefaultGPU = true;
    #   settings = {
    #     StartupWMClass = "Citron";
    #     GenericName = "Nintendo Switch Emulator";
    #   };
    # };
  };
}
