# Enhanced garbage collection configuration for nix-serve host
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Automatic garbage collection configuration
  nix.gc = {
    automatic = true;
    dates = "daily";
    options =
      let
        keepDays = 30;
        minFree = "10G";
        maxStore = "500G";
      in
      ''
        --delete-older-than ${toString keepDays}d
        --max-freed ${maxStore}
      '';
    persistent = true;
    randomizedDelaySec = 1800;
  };

  # Enhanced Nix store optimization settings
  nix.settings = {
    keep-derivations = true;
    keep-outputs = true;
    auto-optimise-store = true;
    min-free = lib.mkForce (128 * 1024 * 1024); # 128MB minimum free
    max-free = lib.mkForce (10 * 1024 * 1024 * 1024); # 10GB target free space
  };

  # Add a service to clean up old nix-serve cache entries
  systemd.services.nix-serve-cleanup = {
    description = "Clean up old nix-serve cache entries";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cleanup-cache" ''
        #!${lib.getExe pkgs.bash}

        # Collect garbage for unreferenced paths
        ${pkgs.nix}/bin/nix-collect-garbage

        echo "Cache cleanup completed"
      '';
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.nix-serve-cleanup = {
    description = "Daily nix-serve cache cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = 3600;
    };
  };
}
