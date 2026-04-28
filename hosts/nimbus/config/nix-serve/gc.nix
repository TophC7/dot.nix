# Enhanced garbage collection configuration for nix-serve host
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Automatic garbage collection configuration
  # Conservative settings since this is a binary cache server
  nix.gc = {
    automatic = true;
    dates = lib.mkForce "Mon *-*-* 03:30:00";
    options = lib.mkForce (
      let
        keepDays = 60; # Extended from 30 - gives other hosts time to sync
        maxStore = "500G";
      in
      "--delete-older-than ${toString keepDays}d --max-freed ${maxStore}"
    );
    persistent = true;
    randomizedDelaySec = lib.mkForce "45min";
  };

  # Enhanced Nix store optimization settings
  nix.settings = {
    keep-derivations = true;
    keep-outputs = true;
    keep-env-derivations = true; # Keep derivations from nix develop/shell
    auto-optimise-store = true;
    min-free = lib.mkForce (128 * 1024 * 1024); # 128MB minimum free
    max-free = lib.mkForce (10 * 1024 * 1024 * 1024); # 10GB target free space
  };

  # nix.gc above is the only garbage collection path. Keeping a second
  # nix-collect-garbage timer makes write-heavy store cleanup harder to reason
  # about on this host.
}
