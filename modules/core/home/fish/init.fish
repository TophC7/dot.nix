## TERMINAL FIXES ##

# HACK: Some terminals or TUI apps leave fish in kitty keyboard protocol
# mode, which turns Ctrl-C and other keys into raw CSI-u sequences.
if not contains -- no-keyboard-protocols $fish_features
    set -ga fish_features no-keyboard-protocols
end

# VSCode still needs the older query-term workaround as well.
if set -q VSCODE_INJECTION
    if not contains -- query-term=- $fish_features
        set -ga fish_features query-term=-
    end
end

function __reset_terminal_state
    # Restore the tty to sane line discipline and drop terminal input modes
    # that commonly leak out of TUIs and leave the shell unreadable.
    command stty sane </dev/tty >/dev/tty 2>/dev/null

    # Disable focus reporting and kitty keyboard protocol reporting.
    printf '\e[?1004l\e[<u'
end

__reset_terminal_state

# Re-apply the reset when a command exits or when the shell itself exits.
function __reset_terminal_state_postexec --on-event fish_postexec
    __reset_terminal_state
end

function __reset_terminal_state_exit --on-event fish_exit
    __reset_terminal_state
end

## GREETING ##

function fish_greeting
    if not string match -q "*ghostty*" "$TERM"
        fastfetch --logo-type sixel
    else
        fastfetch
    end
end

## ALIASES ##

abbr -a bs bonk s
abbr -a ls eza
abbr -a s ssh
abbr -a tt gtrash put
abbr -a zj "zellij attach --create main"

# NOTE: rm is intentionally blocked — use gtrash put (or tt) instead
function rm
    if test (count $argv) -gt 0
        echo "Error: 'rm' is protected. Please use 'gtrash put' or 'tt' command instead."
    end
end

## FUNCTIONS ##

function zipz
    if test (count $argv) -ne 2
        echo "Usage: zipz <directory> <output_filename>"
        return 1
    end

    set directory $argv[1]
    set output_file $argv[2]

    if not test -d $directory
        echo "Error: '$directory' is not a valid directory."
        return 1
    end

    # correct extension to .tar.zst
    if not string match -q "*tar.zst" $output_file
        set base (string replace -r '\\..*$' '' $output_file)
        set output_file "$base.tar.zst"
        echo "Output filename corrected to: $output_file"
    end

    if test -f $output_file
        echo "Error: Output file '$output_file' already exists. Please remove it or choose another name."
        return 1
    end

    # tar to stdout, pipe through zstd with 5 threads at level 15
    tar cf - $directory | nix run nixpkgs#zstd -- -c -T5 -15 -v >$output_file

    if test $status -eq 0
        echo "Compression successful: $output_file"
    else
        echo "Compression failed."
        return 1
    end
end

function unzipz
    if test (count $argv) -ne 2
        echo "Usage: unzipz <input_compressed_file> <destination_directory>"
        return 1
    end

    set input_file $argv[1]
    set destination $argv[2]

    if not test -f $input_file
        echo "Error: '$input_file' is not a valid file."
        return 1
    end

    if not test -d $destination
        mkdir -p $destination
        if test $status -ne 0
            echo "Error: Failed to create destination directory '$destination'."
            return 1
        end
    end

    cat $input_file | nix run nixpkgs#zstd -- -d -c -v | tar xf - -C $destination

    if test $status -eq 0
        echo "Decompression successful: files extracted to $destination"
    else
        echo "Decompression failed."
        return 1
    end
end
