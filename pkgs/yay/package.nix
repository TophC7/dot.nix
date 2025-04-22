# I just missed writing yay in terminal
{ pkgs, lib, ... }:
let
  mainScript = ''
    #!${lib.getExe pkgs.fish}

    # Helper functions for colored output
    function __yay_red
      printf "\033[31m[!] %s\033[0m\n" $argv[1]
    end

    function __yay_green
      printf "\033[32m[+] %s\033[0m\n" $argv[1]
    end

    function __yay_yellow
      printf "\033[33m[*] %s\033[0m\n" $argv[1]
    end

    function __yay_blue
      printf "\033[34m[i] %s\033[0m\n" $argv[1]
    end

    # Function to determine the flake path
    function __yay_get_flake_path
      set -l path_arg $argv[1]
      set -l flake_path ""

      # Priority: 1. Path arg, 2. FLAKE env var, 3. Current directory
      if test -n "$path_arg"
        # redirect diagnostics to stderr so only the path comes out on stdout
        __yay_yellow "Using flake path from argument: $path_arg" >&2
        set flake_path $path_arg
      else if set -q FLAKE
        __yay_yellow "Using flake path from FLAKE env var: $FLAKE" >&2
        set flake_path $FLAKE
      else
        set flake_path (pwd)
        __yay_yellow "Using current directory as flake path: $flake_path" >&2
      end

      # Verify the flake path has a flake.nix
      if not test -f "$flake_path/flake.nix"
        __yay_red "No flake.nix found in $flake_path" >&2
        return 1
      end

      # emit only the path on stdout
      echo $flake_path
    end

    # Function to clean home manager backups
    function __yay_clean_hm_backups
      __yay_yellow "««« CLEARING HOME-MANAGER BACKUPS »»»"
      set total_files (find ~/.config -type f -name "*.homeManagerBackupFileExtension" | wc -l)

      if test $total_files -eq 0
        __yay_green "No home manager backup files found"
        return 0
      end

      set counter 0
      find ~/.config -type f -name "*.homeManagerBackupFileExtension" | while read -l file
        set counter (math $counter + 1)
        echo -n (printf "\rDeleting file %d of %d" $counter $total_files)
        rm $file
      end
      echo # new line after progress
      __yay_green "Removed $total_files home manager backup files"
    end

    # Command: rebuild
    function __yay_rebuild
      set -l options h/help 'p/path=' 'H/host=' t/trace
      argparse $options -- $argv
      or return 1

      if set -ql _flag_help
        echo "Usage: yay rebuild [OPTIONS]"
        echo "Options:"
        echo "  -p, --path PATH   Path to the Nix configuration (overrides FLAKE env var)"
        echo "  -H, --host HOST   Hostname to build for (default: current hostname)"
        echo "  -t, --trace   Enable trace output"
        echo "  -h, --help  Show this help message"
        return 0
      end

      # Get the flake path
      set -l flake_path (__yay_get_flake_path $_flag_path)
      if test $status -ne 0
        return 1
      end

      # Determine hostname
      set -l host
      if set -ql _flag_host
        set host $_flag_host
      else
        set host (hostname)
      end

      # Clean home manager backups first
      __yay_clean_hm_backups

      # Run the rebuild
      __yay_green "««« REBUILDING SYSTEM »»»"
      __yay_green "Building configuration for host: $host"
      __yay_green "Using flake at: $flake_path"

      # Set the repo path for nh
      set -x REPO_PATH $flake_path

      # Change to the flake directory
      set -l original_dir (pwd)
      cd $flake_path

      # Execute nh os switch
      if set -ql _flag_trace
        nh os switch . -- --impure --show-trace
      else
        nh os switch . -- --impure
      end

      set -l result $status

      # Return to original directory
      cd $original_dir

      if test $result -eq 0
        __yay_green "System rebuild completed successfully!"
      else
        __yay_red "System rebuild failed with exit code $result"
      end

      return $result
    end

    # Command: update
    function __yay_update
      set -l options h/help 'p/path='
      argparse $options -- $argv
      or return 1

      if set -ql _flag_help
        echo "Usage: yay update [OPTIONS]"
        echo "Options:"
        echo "  -p, --path PATH   Path to the Nix configuration (overrides FLAKE env var)"
        echo "  -h, --help  Show this help message"
        return 0
      end

      # Get the flake path
      set -l flake_path (__yay_get_flake_path $_flag_path)
      if test $status -ne 0
        return 1
      end

      __yay_green "««« UPDATING FLAKE INPUTS »»»"
      __yay_green "Using flake at: $flake_path"

      # Change to the flake directory
      set -l original_dir (pwd)
      cd $flake_path

      # Update the flake inputs
      nix flake update
      set -l result $status

      # Return to original directory
      cd $original_dir

      if test $result -eq 0
        __yay_green "Flake inputs updated successfully!"
      else
        __yay_red "Failed to update flake inputs with exit code $result"
      end

      return $result
    end

    # Command: garbage
    function __yay_garbage
      set -l options h/help
      argparse $options -- $argv
      or return 1

      if set -ql _flag_help
        echo "Usage: yay garbage"
        echo "Clears all possible garbage from the Nix store"
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
      end

      # ask for sudo once up-front
      __yay_yellow "Requesting sudo credentials…"
      sudo -v

      __yay_green "««« CLEANING NIX GARBAGE »»»"

      __yay_yellow "Running: sudo nh clean all"
      sudo nh clean all

      __yay_yellow "Running: nh clean all"
      nh clean all

      __yay_yellow "Running: sudo nix-collect-garbage --delete-old"
      sudo nix-collect-garbage --delete-old

      __yay_yellow "Running: nix-collect-garbage --delete-old"
      nix-collect-garbage --delete-old

      __yay_yellow "Running: sudo nix-store --gc"
      sudo nix-store --gc

      __yay_yellow "Running: nix-store --gc"
      nix-store --gc

      __yay_green "Garbage collection completed successfully!"
      return 0
    end

    # Command: try
    function __yay_try
      set -l options h/help
      argparse $options -- $argv
      or return 1

      if set -ql _flag_help || test (count $argv) -eq 0
        echo "Usage: yay try PACKAGE [PACKAGE...]"
        echo "Creates a shell with the specified package(s)"
        echo "Options:"
        echo "  -h, --help  Show this help message"
        return 0
      end

      __yay_green "««« CREATING NIX SHELL »»»"
      __yay_yellow "Loading packages: $argv"

      # Run nix-shell with the provided packages and launch fish as the interactive shell
      nix-shell -p $argv --command fish

      return $status
    end

    # Show help
    function __yay_help
      echo "Usage: yay COMMAND [OPTIONS]"
      echo ""
      echo "A wrapper around Nix commands"
      echo ""
      echo "Commands:"
      echo "  rebuild  Rebuild the NixOS configuration"
      echo "  update   Update flake inputs"
      echo "  garbage  Clean up the Nix store"
      echo "  try    Create a shell with the specified package(s)"
      echo "  help   Show this help message"
      echo ""
      echo "Run 'yay COMMAND --help' for command-specific help"
    end

    # Main script entry point
    if test (count $argv) -eq 0
      __yay_help
      exit 1
    end

    set -l cmd $argv[1]
    set -l cmd_args $argv[2..-1]

    switch $cmd
      case rebuild
        __yay_rebuild $cmd_args
      case update
        __yay_update $cmd_args
      case garbage
        __yay_garbage $cmd_args
      case try
        __yay_try $cmd_args
      case -h --help help
        __yay_help
      case '*'
        __yay_red "Unknown command: $cmd"
        __yay_help
        exit 1
    end
  '';

  completionsScript = ''
    # Complete the main command
    complete -c yay -f

    # Complete the top-level subcommands
    complete -c yay -n "__fish_use_subcommand" -a rebuild -d "Rebuild the NixOS configuration"
    complete -c yay -n "__fish_use_subcommand" -a update -d "Update flake inputs"
    complete -c yay -n "__fish_use_subcommand" -a garbage -d "Clean up the Nix store"
    complete -c yay -n "__fish_use_subcommand" -a try -d "Create a shell with the specified package(s)"
    complete -c yay -n "__fish_use_subcommand" -a help -d "Show help message"

    # Options for 'rebuild'
    complete -c yay -n "__fish_seen_subcommand_from rebuild" -s p -l path -r -d "Path to the Nix configuration"
    complete -c yay -n "__fish_seen_subcommand_from rebuild" -s H -l host -r -d "Hostname to build for"
    complete -c yay -n "__fish_seen_subcommand_from rebuild" -s t -l trace -d "Enable trace output"
    complete -c yay -n "__fish_seen_subcommand_from rebuild" -s h -l help -d "Show help message"

    # Options for 'update'
    complete -c yay -n "__fish_seen_subcommand_from update" -s p -l path -r -d "Path to the Nix configuration"
    complete -c yay -n "__fish_seen_subcommand_from update" -s h -l help -d "Show help message"

    # Options for 'garbage'
    complete -c yay -n "__fish_seen_subcommand_from garbage" -s h -l help -d "Show help message"

    # Options for 'try'
    complete -c yay -n "__fish_seen_subcommand_from try" -s h -l help -d "Show help message"

    # Package suggestions for 'try' (using nix-env's available packages)
    function __yay_list_packages
      # Use persistent cache file in /tmp (lasts until reboot)
      set -l cache_file "/tmp/yay_packages_cache"
      
      # Load from cache if it exists
      if test -f "$cache_file"
        cat "$cache_file"
        return 0
      end
      
      # Otherwise, fetch packages and store in cache
      echo -n "Loading packages..." >&2
      # Run nix-env but redirect warnings to /dev/null
      set -l packages (nix-env -qa --json 2>/dev/null | jq -r 'keys[]' 2>/dev/null)
      
      # Process packages to remove namespace prefix (like "nixos.", "nixpkgs.", etc.)
      set -l cleaned_packages
      for pkg in $packages
        set -l cleaned_pkg (string replace -r '^[^.]+\.' ''\'''\' $pkg)
        set -a cleaned_packages $cleaned_pkg
      end
      
      # Save to cache file for future shell sessions
      printf "%s\n" $cleaned_packages > "$cache_file"
      echo " done!" >&2
      
      # Output the packages
      printf "%s\n" $cleaned_packages
    end

    complete -c yay -n "__fish_seen_subcommand_from try; and not __fish_is_switch" -a "(__yay_list_packages)" -d "Nix package"
  '';

  # Create the main script
  scriptFile = pkgs.writeTextFile {
    name = "yay";
    text = mainScript;
    executable = true;
    destination = "/bin/yay";
  };

  # Create the completions file
  completionsFile = pkgs.writeTextFile {
    name = "yay-completions";
    text = completionsScript;
    destination = "/share/fish/vendor_completions.d/yay.fish";
  };
in
pkgs.symlinkJoin {
  name = "yay";
  paths = [
    scriptFile
    completionsFile
  ];
  buildInputs = [ pkgs.makeWrapper ];

  # Make sure nh is always available in PATH
  postBuild = ''
    wrapProgram $out/bin/yay \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.nh
          pkgs.jq
        ]
      }
  '';

  meta = with lib; {
    description = "A convenient wrapper around Nix commands with fish completions";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ "Tophc7" ];
  };
}
