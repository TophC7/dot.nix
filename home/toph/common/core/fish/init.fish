function cd
    zoxide $argv
end

function ls
    eza $argv
end

# Discourage using rm command
function rm
    if test (count $argv) -gt 0
        echo "Error: 'rm' is protected. Please use 'trashy' command instead."
    end
end

# SSH function, just for convenience since I use it a lot
function s
    set user (whoami)
    set keyfile ""
    set host ""

    set args $argv
    while test (count $args) -gt 0
        switch $args[1]
            case -u
                if test (count $args) -ge 2
                    set user $args[2]
                    set args $args[3..-1]
                else
                    echo "Error: Option -u requires a username argument."
                    echo "Usage: s [-u username] [-i keyfile] host"
                    return 1
                end
            case -i
                if test (count $args) -ge 2
                    set keyfile $args[2]
                    set args $args[3..-1]
                else
                    echo "Error: Option -i requires a keyfile argument."
                    echo "Usage: s [-u username] [-i keyfile] host"
                    return 1
                end
            case '*'
                set host $args[1]
                set args $args[2..-1]
        end
    end

    if test -z "$host"
        echo "Error: Missing host."
        echo "Usage: s [-u username] [-i keyfile] host"
        return 1
    end

    if test -n "$keyfile"
        ssh -i $keyfile $user@$host
    else
        ssh $user@$host
    end
end

function zipz
    # Ensure exactly two arguments are provided
    if test (count $argv) -ne 2
        echo "Usage: bipzstd <directory> <output_filename>"
        return 1
    end

    set directory $argv[1]
    set output_file $argv[2]

    # Verify that the specified directory exists
    if not test -d $directory
        echo "Error: '$directory' is not a valid directory."
        return 1
    end

    # Correct output filename to always end with tar.zst
    if not string match -q "*tar.zst" $output_file
        # Remove any existing extension, if present
        set base (string replace -r '\..*$' '' $output_file)
        set output_file "$base.tar.zst"
        echo "Output filename corrected to: $output_file"
    end

    # Check if the output file already exists to avoid accidental overwrite
    if test -f $output_file
        echo "Error: Output file '$output_file' already exists. Please remove it or choose another name."
        return 1
    end

    # Create a tar archive of the directory and compress it with zstd.
    # - The tar command outputs the archive to stdout.
    # - zstd compresses it using 4 threads (-T4) and a compression level of 12 (-12).
    # - The -c flag forces zstd to write to stdout.
    tar cf - $directory | nix run nixpkgs#zstd -- -c -T5 -15 -v > $output_file

    # Check the exit status of the pipeline
    if test $status -eq 0
        echo "Compression successful: $output_file"
    else
        echo "Compression failed."
        return 1
    end
end

function unzipz
    # Ensure exactly two arguments are provided
    if test (count $argv) -ne 2
        echo "Usage: unzipz <input_compressed_file> <destination_directory>"
        return 1
    end

    set input_file $argv[1]
    set destination $argv[2]

    # Verify that the input file exists
    if not test -f $input_file
        echo "Error: '$input_file' is not a valid file."
        return 1
    end

    # Create the destination directory if it does not exist
    if not test -d $destination
        mkdir -p $destination
        if test $status -ne 0
            echo "Error: Failed to create destination directory '$destination'."
            return 1
        end
    end

    # Decompress the file:
    # - The zstd command (via nix) decompresses the compressed file,
    #   using the -d flag (decompress) and -c to output to stdout.
    # - The decompressed stream is piped to tar to extract its contents into the destination directory.
    cat $input_file | nix run nixpkgs#zstd -- -d -c -v | tar xf - -C $destination

    # Check the exit status of the pipeline
    if test $status -eq 0
        echo "Decompression successful: files extracted to $destination"
    else
        echo "Decompression failed."
        return 1
    end
end

set fish_greeting # Disable greeting

fastfetch
