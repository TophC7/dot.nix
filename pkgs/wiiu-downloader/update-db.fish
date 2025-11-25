#!/usr/bin/env fish

# Update db.go from WiiU downloader API
# Run this script when you need to update the title database

set -l script_dir (dirname (status -f))
set -l db_file "$script_dir/db.go"

echo "Updating WiiU Downloader database..."

# Download with proper headers
if curl --http1.1 \
        -H "User-Agent: NUSspliBuilder/2.1" \
        "https://napi.v10lator.de/db?t=go" \
        -o "$db_file"
    echo "Successfully downloaded db.go"
    echo "File saved to: $db_file"

    # Show update timestamp in the file
    set -l timestamp (head -2 "$db_file" | tail -1)
    echo "⌛ $timestamp"
else
    echo "❌ Failed to download db.go"
    exit 1
end
