{ pkgs, ... }:
pkgs.writeScript "backup-wrapper" ''
  #!/usr/bin/env fish

  #==========================================================#
  # Function definitions                                     #
  #==========================================================#

  # Set up colors for prettier output
  set -l blue (set_color blue)
  set -l green (set_color green)
  set -l yellow (set_color yellow) 
  set -l red (set_color red)
  set -l cyan (set_color cyan)
  set -l magenta (set_color magenta)
  set -l bold (set_color --bold)
  set -l normal (set_color normal)

  # Define log file path
  set -g log_file ""

  function setup_logging
    set -g log_file "$argv[1]/backup.log"
    echo "# Backup Wrapper Log - Started at "(date) > $log_file
    echo "# =====================================================" >> $log_file
  end

  # Use conditional tee: if log_file is set, tee output; otherwise echo normally.
  function print_header
    set -l header "$blue═══════════════[ $bold$argv[1]$normal$blue ]═══════════════$normal"
    if test -n "$log_file"
      echo $header | tee -a $log_file
    else
      echo $header
    end
  end

  function print_step
    set -l msg "$green→ $bold$argv[1]$normal"
    if test -n "$log_file"
      echo $msg | tee -a $log_file
    else
      echo $msg
    end
  end

  function print_info
    set -l msg "$cyan•$normal $argv[1]"
    if test -n "$log_file"
      echo $msg | tee -a $log_file
    else
      echo $msg
    end
  end

  function print_warning
    set -l msg "$yellow⚠$normal $argv[1]"
    if test -n "$log_file"
      echo $msg | tee -a $log_file >&2
    else
      echo $msg >&2
    end
  end

  function print_error
    set -l msg "$red✖$normal $argv[1]"
    if test -n "$log_file"
      echo $msg | tee -a $log_file >&2
    else
      echo $msg >&2
    end
  end

  function print_success
    set -l msg "$green✓$normal $argv[1]"
    if test -n "$log_file"
      echo $msg | tee -a $log_file
    else
      echo $msg
    end
  end

  function print_usage
    print_header "Backup Wrapper Usage"
    if test -n "$log_file"
      echo "Usage: backup_wrapper [OPTIONS] -- COMMAND [ARGS...]" | tee -a $log_file
      echo "Options:" | tee -a $log_file
      echo "  -p, --path PATH       Path to backup" | tee -a $log_file
      echo "  -o, --output PATH     Output directory for backups" | tee -a $log_file
      echo "  -m, --max NUMBER      Maximum number of backups to keep (default: 5)" | tee -a $log_file
      echo "  -d, --delay SECONDS   Delay before backup after changes (default: 5)" | tee -a $log_file
      echo "  -h, --help            Show this help message" | tee -a $log_file
    else
      echo "Usage: backup_wrapper [OPTIONS] -- COMMAND [ARGS...]"
      echo "Options:"
      echo "  -p, --path PATH       Path to backup"
      echo "  -o, --output PATH     Output directory for backups"
      echo "  -m, --max NUMBER      Maximum number of backups to keep (default: 5)"
      echo "  -d, --delay SECONDS   Delay before backup after changes (default: 5)"
      echo "  -h, --help            Show this help message"
    end
  end

  # This is the critical function - needs to return *only* the backup file path
  function backup_path
    set -l src $argv[1]
    set -l out $argv[2]
    set -l timestamp (date +"%Y%m%d-%H%M%S")
    set -l backup_file "$out/backup-$timestamp.tar.zst"
    
    # Log messages to stderr so they don't interfere with the function output
    echo "$green→$normal Backing up to $yellow$backup_file$normal" >&2 | tee -a $log_file
    pushd (dirname "$src") >/dev/null
    tar cf - (basename "$src") | ${pkgs.zstd}/bin/zstd -c -T5 -15 > "$backup_file" 2>> $log_file
    set -l exit_status $status
    popd >/dev/null
    
    if test $exit_status -eq 0
      # IMPORTANT: Only output the backup file path, nothing else
      echo $backup_file
    else
      echo "$red✖$normal Backup operation failed!" >&2 | tee -a $log_file
      return 1
    end
  end

  function rotate_backups
    set -l output_dir $argv[1]
    set -l max_backups $argv[2]
    
    set -l backups (ls -t "$output_dir"/backup-*.tar.zst 2>/dev/null)
    set -l num_backups (count $backups)
    
    if test $num_backups -gt $max_backups
      print_step "Rotating backups, keeping $max_backups of $num_backups"
      for i in (seq (math "$max_backups + 1") $num_backups)
        print_info "Removing old backup: $yellow$backups[$i]$normal" 
        rm -f "$backups[$i]"
      end
    end
  end

  #==========================================================#
  # Argument parsing                                         #
  #==========================================================#

  # Parse arguments
  set -l backup_path ""
  set -l output_dir ""
  set -l max_backups 5
  set -l delay 5
  set -l cmd ""

  while count $argv > 0
    switch $argv[1]
      case -h --help
        print_usage
        exit 0
      case -p --path
        set -e argv[1]
        set backup_path $argv[1]
        set -e argv[1]
      case -o --output
        set -e argv[1]
        set output_dir $argv[1]
        set -e argv[1]
      case -m --max
        set -e argv[1]
        set max_backups $argv[1]
        set -e argv[1]
      case -d --delay
        set -e argv[1]
        set delay $argv[1]
        set -e argv[1]
      case --
        set -e argv[1]
        set cmd $argv
        break
      case '*'
        print_error "Unknown option $argv[1]"
        print_usage
        exit 1
    end
  end

  #==========================================================#
  # Validation & Setup                                       #
  #==========================================================#

  # Ensure the output directory exists
  mkdir -p "$output_dir" 2>/dev/null

  # Set up logging 
  setup_logging "$output_dir"

  print_header "Backup Wrapper Starting"

  # Log the original command
  echo "# Original command: $argv" >> $log_file

  # Validate arguments
  if test -z "$backup_path" -o -z "$output_dir" -o -z "$cmd"
    print_error "Missing required arguments"
    print_usage
    exit 1
  end

  # Display configuration
  print_info "Backup path:   $yellow$backup_path$normal"
  print_info "Output path:   $yellow$output_dir$normal"
  print_info "Max backups:   $yellow$max_backups$normal"
  print_info "Backup delay:  $yellow$delay seconds$normal"
  print_info "Command:       $yellow$cmd$normal"
  print_info "Log file:      $yellow$log_file$normal"

  # Validate the backup path exists
  if not test -e "$backup_path"
    print_error "Backup path '$backup_path' does not exist"
    exit 1
  end


  #==========================================================#
  # Initial backup                                           #
  #==========================================================#

  print_header "Creating Initial Backup"

  # Using command substitution to capture only the path output
  set -l initial_backup (backup_path "$backup_path" "$output_dir")
  set -l status_code $status

  if test $status_code -ne 0
    print_error "Initial backup failed"
    exit 1
  end
  print_success "Initial backup created: $yellow$initial_backup$normal"

  #==========================================================#
  # Start wrapped process                                    #
  #==========================================================#

  print_header "Starting Wrapped Process"

  # Start the wrapped process in the background
  print_step "Starting wrapped process: $yellow$cmd$normal"

  # Using exactly the same execution method as the original working script
  $cmd >> $log_file 2>&1 &
  set -l pid $last_pid
  print_success "Process started with PID: $yellow$pid$normal"

  # Set up cleanup function
  function cleanup --on-signal INT --on-signal TERM
    print_warning "Caught signal, cleaning up..."
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
    echo "# Script terminated by signal at "(date) >> $log_file
    exit 0
  end

  #==========================================================#
  # Monitoring loop                                          #
  #==========================================================#

  print_header "Monitoring for Changes"

  # Monitor for changes and create backups
  set -l change_detected 0
  set -l last_backup_time (date +%s)

  print_step "Monitoring $yellow$backup_path$normal for changes..."

  while true
    # Check if the process is still running
    if not kill -0 $pid 2>/dev/null
      print_warning "Wrapped process exited, stopping monitor"
      break
    end
    
    # Using inotifywait to detect changes
    ${pkgs.inotify-tools}/bin/inotifywait -r -q -e modify,create,delete,move "$backup_path" -t 1
    set -l inotify_status $status
    
    if test $inotify_status -eq 0
      # Change detected
      set change_detected 1
      set -l current_time (date +%s)
      set -l time_since_last (math "$current_time - $last_backup_time")
      
      if test $time_since_last -ge $delay
        print_step "Changes detected, creating backup"
        set -l new_backup (backup_path "$backup_path" "$output_dir")
        set -l backup_status $status
        
        if test $backup_status -eq 0
          print_success "Backup created: $yellow$new_backup$normal"
          rotate_backups "$output_dir" "$max_backups"
          set last_backup_time (date +%s)
          set change_detected 0
        else
          print_error "Backup failed"
        end
      else
        print_info "Change detected, batching with other changes ($yellow$delay$normal seconds delay)"
      end
    else if test $change_detected -eq 1
      # No new changes but we had some changes before
      set -l current_time (date +%s)
      set -l time_since_last (math "$current_time - $last_backup_time")
      
      if test $time_since_last -ge $delay
        print_step "Creating backup after batching changes"
        set -l new_backup (backup_path "$backup_path" "$output_dir")
        set -l backup_status $status
        
        if test $backup_status -eq 0
          print_success "Backup created: $yellow$new_backup$normal"
          rotate_backups "$output_dir" "$max_backups"
          set last_backup_time (date +%s)
          set change_detected 0
        else
          print_error "Backup failed"
        end
      end
    end
  end

  #==========================================================#
  # Cleanup & Exit                                           #
  #==========================================================#

  print_header "Finishing Up"

  # Wait for the wrapped process to finish
  print_step "Waiting for process to finish..."
  wait $pid
  set -l exit_code $status
  print_success "Process finished with exit code: $yellow$exit_code$normal"

  # Add final log entry
  echo "# Script completed at "(date)" with exit code $exit_code" >> $log_file

  exit $exit_code
''
