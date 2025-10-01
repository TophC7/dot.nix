#!/usr/bin/env fish

# Update script for olm-tunnel package
# Usage: ./update.fish <version>
# Example: ./update.fish 1.2.0

# yay try go jq nix-prefetch-github -- ./update.fish 1.2.0

set -l new_version $argv[1]

if test -z "$new_version"
    echo "Error: Please provide a version number"
    echo "Usage: ./update.fish <version>"
    echo "Example: ./update.fish 1.2.0"
    exit 1
end

echo "Updating olm-tunnel to version $new_version..."

# Fetch the source hash for the new version
echo "Fetching source hash..."
set -l src_hash (nix-prefetch-github fosrl olm --rev $new_version 2>/dev/null | jq -r '.hash')

if test -z "$src_hash"
    echo "Error: Failed to fetch source hash for version $new_version"
    echo "Please verify the version exists on GitHub"
    exit 1
end

echo "Source hash: $src_hash"

# Create a temporary directory for vendor hash calculation
set -l tmpdir (mktemp -d)
echo "Working in temporary directory: $tmpdir"

# Clone the repository at the specific version
echo "Cloning repository at version $new_version..."
git clone --quiet --depth 1 --branch $new_version https://github.com/fosrl/olm.git $tmpdir/olm 2>/dev/null

if test $status -ne 0
    echo "Error: Failed to clone repository at version $new_version"
    rm -rf $tmpdir
    exit 1
end

# Calculate vendor hash
echo "Calculating vendor hash..."
pushd $tmpdir/olm

# Download go modules
go mod download 2>/dev/null
if test $status -ne 0
    echo "Error: Failed to download Go modules"
    popd
    rm -rf $tmpdir
    exit 1
end

# Generate vendor directory and calculate hash
go mod vendor 2>/dev/null
set -l vendor_hash (nix hash path vendor 2>/dev/null)

popd

if test -z "$vendor_hash"
    echo "Error: Failed to calculate vendor hash"
    rm -rf $tmpdir
    exit 1
end

echo "Vendor hash: $vendor_hash"

# Clean up temporary directory
rm -rf $tmpdir

# Update the package.nix file
set -l package_file (dirname (status --current-filename))/package.nix

echo "Updating package.nix..."

# Update version
sed -i "s|version = \".*\";|version = \"$new_version\";|" $package_file

# Update source hash  
sed -i "s|hash = \"sha256-.*\";|hash = \"$src_hash\";|" $package_file

# Update vendor hash
sed -i "s|vendorHash = \"sha256-.*\";|vendorHash = \"$vendor_hash\";|" $package_file

echo "Successfully updated olm-tunnel to version $new_version"
echo ""
echo "Updated values:"
echo "  Version: $new_version"
echo "  Source hash: $src_hash"
echo "  Vendor hash: $vendor_hash"
echo ""
echo "Please test the build with:"
echo "  nix build .#olm-tunnel"
