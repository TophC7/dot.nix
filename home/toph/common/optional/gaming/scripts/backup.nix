{
  pkgs,
  ...
}:
pkgs.writeScript "backup-wrapper" ''
  #!/usr/bin/env fish

  ## Helpers ##
  function backup
    # Uses $src, $dest, $max_backups from outer scope
    set timestamp (date +%Y%m%d-%H%M%S)
    set outfile "$dest/backup-$timestamp.tar.zst"

    mkdir -p $dest
    echo "→ Creating backup: $outfile"

    tar cf - $src |
      ${pkgs.zstd}/bin/zstd -- -c -T5 -15 -v > $outfile

    # Rotate: keep only the newest $max_backups
    set files (ls -1t $dest/backup-*.tar.zst)
    if test (count $files) -gt $max_backups
      for f in $files[(math "$max_backups + 1")..-1]
        rm $f
        echo "  • Removed old backup: $f"
      end
    end
  end

  function periodic_backups --argument-names pid
    while test -d /proc/$pid
      sleep $interval
      echo "Interval backup at "(date)
      backup
    end
  end


  ## Arg parsing ##
  if test (count $argv) -lt 5
    echo "Usage: $argv[0] <src> <dest> <interval_s> <max_backups> -- <program> [args...]"
    exit 1
  end

  set src         $argv[1]
  set dest        $argv[2]
  set interval    $argv[3]
  set max_backups $argv[4]

  # strip leading “--” if present
  set rest $argv[5..-1]
  if test $rest[1] = "--"
    set rest $rest[2..-1]
  end


  ## Workflow ##
  echo "BACKUP: Initial backup of '$src' → '$dest'"
  backup

  echo "BACKUP: Launching your program: $rest"
  # fish will expand $rest as command + args
  $rest &; set pid $last_pid
  echo "   → PID is $pid"

  echo "BACKUP: Starting periodic backups every $interval seconds…"
  periodic_backups $pid &

  echo "BACKUP: Waiting for PID $pid to exit…"
  wait $pid

  echo "BACKUP: Program exited at "(date)"; doing final backup."
  backup

  exit 0
''
