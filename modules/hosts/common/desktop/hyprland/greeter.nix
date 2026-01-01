# DankMaterialShell greeter for Hyprland
{
  host,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hyprlandPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  # Session wrapper script that manages systemd targets and runs Hyprland
  # This mimics UWSM's session management without the complexity
  hyprlandSessionScript = pkgs.writeShellScriptBin "hyprland-session" ''
    # Cleanup function for session exit
    cleanup() {
      # Stop graphical session target (this stops DMS and other services)
      ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target 2>/dev/null || true

      # Clean up environment
      ${pkgs.systemd}/bin/systemctl --user unset-environment \
        WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE 2>/dev/null || true

      # Reset any failed units
      ${pkgs.systemd}/bin/systemctl --user reset-failed 2>/dev/null || true
    }
    trap cleanup EXIT

    # Export session environment for child processes
    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=Hyprland

    # Start graphical-session-pre.target first (for services that need to run before compositor)
    ${pkgs.systemd}/bin/systemctl --user start graphical-session-pre.target 2>/dev/null || true

    # Run Hyprland via start-hyprland wrapper
    # This handles plugins, config, and environment setup
    exec ${hyprlandPackage}/bin/start-hyprland
  '';

  # Desktop entry for display managers / greetd
  hyprlandDesktopEntry = pkgs.stdenv.mkDerivation {
    pname = "hyprland-dms-session";
    version = "1.0";

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/hyprland-dms.desktop <<EOF
      [Desktop Entry]
      Name=Hyprland (DMS)
      Comment=Hyprland with DankMaterialShell
      Exec=${hyprlandSessionScript}/bin/hyprland-session
      Type=Application
      DesktopNames=Hyprland
      EOF
    '';

    passthru.providedSessions = [ "hyprland-dms" ];
  };

  autoLoginCommand = "${hyprlandSessionScript}/bin/hyprland-session";
in
{
  # Import DMS greeter module
  imports = [ inputs.dankMaterialShell.nixosModules.greeter ];

  # Configure DMS greeter with Hyprland as compositor
  programs.dank-material-shell.greeter = {
    enable = true;

    compositor = {
      name = "sway";
      customConfig = "";
    };

    logs = {
      save = false;
      path = "/var/log/dms-greeter.log";
    };
  };

  # Auto-login if enabled
  services.greetd.settings = lib.mkIf host.autoLogin {
    initial_session = {
      command = autoLoginCommand;
      user = host.user.name;
    };
  };

  # Add custom desktop entry to system path
  environment.systemPackages = [
    pkgs.sway
    hyprlandDesktopEntry
  ];

  # Make the custom session visible to display managers
  services.displayManager.sessionPackages = [ hyprlandDesktopEntry ];
}
