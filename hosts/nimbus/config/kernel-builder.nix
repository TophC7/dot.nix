# Automatic CachyOS kernel update checker and builder
#
# Runs daily to:
# 1. Check if nix-cachyos-kernel has updates OR kernels missing from cache
# 2. Update mix.nix flake.lock if needed
# 3. Build all kernel variants (populates binary cache)
# 4. Commit and push the updated flake.lock
# 5. Send Discord notifications via Apprise
{
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
let
  # Configuration
  repoPath = "/repo/Nix/mix.nix";
  branch = "main";
  serviceUser = host.user.name; # User with ryot group access to /repo

  # Apprise Discord Webhook URL
  # Format: discord://WebhookID/WebhookToken?params
  appriseUrl = "${secrets.service.discord.lenix}?avatar=no&footer=no";

  # Fish script for kernel update checking and building
  kernelUpdateScript = pkgs.writeTextFile {
    name = "kernel-update.fish";
    executable = true;
    text = ''
      #!${lib.getExe pkgs.fish}
      #
      # Kernel Update Checker
      # Checks for nix-cachyos-kernel updates, builds kernels, and pushes changes
      #

      # Use -g (global) for variables accessed inside functions
      set -g repo_path "${repoPath}"
      set -g apprise_url "${appriseUrl}"
      set -g log_prefix "[kernel-builder]"
      set -g kernels linux-ryot linux-ryot-zfs linux-ryot-net

      function log
        echo (date "+%Y-%m-%d %H:%M:%S") "$log_prefix" $argv
      end

      function log_error
        echo (date "+%Y-%m-%d %H:%M:%S") "$log_prefix ERROR:" $argv >&2
      end

      function notify
        set -l body $argv[1]
        printf '%s' "$body" | ${lib.getExe pkgs.apprise} -vv "$apprise_url"
        or log "Failed to send notification (non-critical)"
      end

      # Check if a kernel is built in the nix store
      function kernel_in_cache
        set -l kernel $argv[1]
        # Try to get the store path without building - if it fails, not in cache
        ${lib.getExe pkgs.nix} path-info --impure --expr "
          let
            flake = builtins.getFlake \"path:$repo_path\";
            pkgs = import flake.inputs.nixpkgs {
              system = \"x86_64-linux\";
              overlays = [ flake.overlays.default ];
            };
          in pkgs.$kernel
        " >/dev/null 2>&1
        return $status
      end

      # Build a kernel
      function build_kernel
        set -l kernel $argv[1]
        ${lib.getExe pkgs.nix} build --impure --no-link -L --expr "
          let
            flake = builtins.getFlake \"path:$repo_path\";
            pkgs = import flake.inputs.nixpkgs {
              system = \"x86_64-linux\";
              overlays = [ flake.overlays.default ];
            };
          in pkgs.$kernel
        "
        return $status
      end

      # Ensure we're in the repo
      if not test -d "$repo_path"
        log_error "Repository not found: $repo_path"
        exit 1
      end

      cd "$repo_path"; or begin
        log_error "Failed to cd to $repo_path"
        exit 1
      end

      log "Starting kernel update check..."

      # Fetch latest from remote
      log "Fetching latest changes from origin..."
      git fetch origin; or begin
        log_error "Failed to fetch from origin"
        exit 1
      end

      # Pull any changes
      git pull --ff-only origin ${branch}; or begin
        log_error "Failed to pull from origin (non-fast-forward?)"
        exit 1
      end

      # Get current locked revision
      set -l current_rev (${lib.getExe pkgs.nix} flake metadata --json 2>/dev/null | ${lib.getExe pkgs.jq} -r '.locks.nodes["nix-cachyos-kernel"].locked.rev // empty')

      if test -z "$current_rev"
        log_error "Could not get current nix-cachyos-kernel revision from flake.lock"
        exit 1
      end

      log "Current kernel rev: $current_rev"

      # Get latest revision from upstream (--refresh bypasses flake registry cache)
      set -l latest_rev (${lib.getExe pkgs.nix} flake metadata github:xddxdd/nix-cachyos-kernel/release --json --refresh 2>/dev/null | ${lib.getExe pkgs.jq} -r '.revision // empty')

      if test -z "$latest_rev"
        log_error "Could not get latest nix-cachyos-kernel revision"
        exit 1
      end

      log "Latest kernel rev:  $latest_rev"

      # Check if revision needs updating
      set -l needs_update false
      set -l needs_build false
      set -l missing_kernels

      if test "$current_rev" != "$latest_rev"
        set needs_update true
        set needs_build true
        log "New kernel version available!"
      else
        log "Kernel revision is current, checking if kernels are in cache..."
        # Check if all kernels are in cache
        for kernel in $kernels
          if not kernel_in_cache $kernel
            log "Kernel $kernel is NOT in cache"
            set needs_build true
            set -a missing_kernels $kernel
          else
            log "Kernel $kernel is in cache"
          end
        end
      end

      # Exit if nothing to do
      if not $needs_build
        log "All kernels are up to date and in cache, nothing to do"
        exit 0
      end

      set -l short_current (string sub -l 7 "$current_rev")
      set -l short_latest (string sub -l 7 "$latest_rev")

      # Notify about build starting
      if $needs_update
        log "Updating flake input and building kernels..."
        notify "## 🔄 New CachyOS Kernel
      > **Rev:** \`$short_current\` → \`$short_latest\`
      > Building kernels..."

        # Update the input
        log "Running: nix flake update nix-cachyos-kernel"
        ${lib.getExe pkgs.nix} flake update nix-cachyos-kernel; or begin
          log_error "Failed to update nix-cachyos-kernel input"
          notify "## ❌ Build Failed
      > Failed to update flake input"
          exit 1
        end
      else
        log "Building missing kernels: $missing_kernels"
        notify "## 🔨 Missing from Cache
      > **Rev:** \`$short_current\`
      > $missing_kernels"
      end

      # Build all kernel variants
      log "Building kernel variants (this will take a while)..."

      set -l failed_kernels
      set -l success_kernels

      for kernel in $kernels
        log "Building $kernel..."
        if build_kernel $kernel
          log "Successfully built $kernel"
          set -a success_kernels $kernel
        else
          log_error "Failed to build $kernel"
          set -a failed_kernels $kernel
        end
      end

      # Commit and push if we updated the flake
      if $needs_update
        if not git diff --quiet flake.lock
          log "Committing updated flake.lock..."

          git add flake.lock

          git commit -m "chore: update nix-cachyos-kernel to $short_latest

      Auto-updated by kernel-builder service

      Previous: $short_current
      Current:  $short_latest

      Built: $success_kernels"

          log "Pushing to origin..."
          git push origin ${branch}; or begin
            log_error "Failed to push to origin"
            notify "## ❌ Build Failed
      > Built kernels but failed to push to origin"
            exit 1
          end
        end
      end

      # Send completion notification
      if test (count $failed_kernels) -eq 0
        notify "## ✅ All Kernels Built
      > **Rev:** \`$short_latest\`
      > • linux-ryot
      > • linux-ryot-zfs
      > • linux-ryot-net"
      else
        notify "## ⚠️ Some Builds Failed
      > **Rev:** \`$short_latest\`
      > **✓** $success_kernels
      > **✗** $failed_kernels"
      end

      log "Successfully completed kernel build!"
      log "Kernel update check complete"
    '';
  };
in
{
  # Ensure required packages are available
  environment.systemPackages = with pkgs; [
    apprise
    git
    jq
  ];

  systemd.services.kernel-builder = {
    description = "Check for CachyOS kernel updates and build";

    path = with pkgs; [
      fish
      git
      nix
      jq
      apprise
      openssh # For git push over SSH
      coreutils
    ];

    environment = {
      HOME = "/home/${serviceUser}";
      NIX_PATH = "nixpkgs=${pkgs.path}";
      # Ensure git uses SSH correctly
      GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new";
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${kernelUpdateScript}";
      User = serviceUser;
      Group = "ryot";
      WorkingDirectory = repoPath;

      # Generous timeout for kernel builds (4 hours)
      TimeoutStartSec = "4h";

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "kernel-builder";

      # Hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        repoPath
        "/nix/var"
      ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };
  };

  systemd.timers.kernel-builder = {
    description = "Timer for kernel update checks";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; # Run if missed while system was off
      RandomizedDelaySec = "30min"; # Avoid thundering herd
    };
  };
}
