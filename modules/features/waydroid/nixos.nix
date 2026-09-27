{ pkgs, ... }:
let
  # TODO: automate with monitors.nix when i fix that up again
  width = 1064;
  height = 1904;
in
{
  # Enable Waydroid
  virtualisation.waydroid.enable = true;

  # Required packages
  environment.systemPackages = with pkgs; [
    waydroid
    waydroid-helper
    wl-clipboard # Clipboard sharing

    # Waydroid setup script; run once to initialize
    (pkgs.writeShellScriptBin "waydroid-setup" ''
      #!/usr/bin/env bash
      set -e

      echo "Initializing WayDroid with GApps support..."
      sudo waydroid init -s GAPPS -f

      echo "Setting default WayDroid properties..."
      sudo mkdir -p /var/lib/waydroid

      # Create or update waydroid_base.prop
      echo "persist.waydroid.multi_windows=true" | sudo tee /var/lib/waydroid/waydroid_base.prop
      echo "persist.waydroid.width=${toString width}" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
      echo "persist.waydroid.height=${toString height}" | sudo tee -a /var/lib/waydroid/waydroid_base.prop
      echo "sys.use_memfd=true" | sudo tee -a /var/lib/waydroid/waydroid_base.prop

      echo "Setup complete!"
      echo ""
      echo "To start WayDroid:"
      echo "  1. sudo systemctl start waydroid-container"
      echo "  2. waydroid session start"
      echo "  3. waydroid show-full-ui"
      echo ""
      echo "To install APKs: waydroid app install /path/to/app.apk"
    '')
  ];
}
