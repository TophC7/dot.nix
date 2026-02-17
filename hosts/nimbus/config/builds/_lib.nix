# Build Pipeline Factory
#
# Creates a single systemd service + timer for a per-package build pipeline.
# Generates a Fish script that handles the full lifecycle:
#   git sync -> per-package update + cache check -> build -> commit -> notify
#
# Architecture:
#   Timer -> Pipeline service (git sync -> update/check -> build -> commit -> notify)
#
# This is a simplification over the previous group-based orchestrator. Each
# pipeline handles one set of packages with optional per-package update scripts.
# There are no standalone services or sub-groups — one service, one timer.
#
# Usage:
#   let
#     builds = import ./_lib.nix { inherit lib pkgs secrets host; };
#   in
#   builds.mkPipeline {
#     name = "mix-builder";
#     repoPath = "/path/to/repo";
#     schedule = "04:00";
#     packages = [
#       { name = "my-package"; updateScript = "nix flake update my-input"; }
#       { name = "other-pkg"; }
#     ];
#   }
#
{
  lib,
  pkgs,
  secrets,
  host,
}:
let
  # ── Shared Configuration ──────────────────────────────────────
  serviceUser = host.user.name;
  appriseUrl = "${secrets.service.discord.lenix}?avatar=no&footer=no";
  stateBase = "mix-builder"; # StateDirectory name -> /var/lib/mix-builder/

  nix = lib.getExe pkgs.nix;
  jq = lib.getExe pkgs.jq;
  fish = lib.getExe pkgs.fish;
  apprise = lib.getExe pkgs.apprise;

  # ── Shared Fish Helper Functions ──────────────────────────────
  #
  # Injected into every generated script. Uses $log_tag for context.
  #
  sharedFishFunctions = ''
    function log
      echo (date "+%Y-%m-%d %H:%M:%S") "[$log_tag]" $argv
    end

    function log_error
      echo (date "+%Y-%m-%d %H:%M:%S") "[$log_tag ERROR]" $argv >&2
    end

    function notify
      set -l body $argv[1]
      printf '%s' "$body" | ${apprise} -vv "${appriseUrl}"
      or log "Failed to send notification (non-critical)"
    end

    # Check if a package is already built in the nix store
    function pkg_in_cache
      set -l repo $argv[1]
      set -l pkg $argv[2]
      ${nix} path-info --impure --expr "
        let
          flake = builtins.getFlake \"path:$repo\";
          pkgs = import flake.inputs.nixpkgs {
            system = \"x86_64-linux\";
            overlays = [ flake.overlays.default ];
          };
        in pkgs.$pkg
      " >/dev/null 2>&1
      return $status
    end

    # Build a single package
    function build_pkg
      set -l repo $argv[1]
      set -l pkg $argv[2]
      ${nix} build --impure --no-link -L --expr "
        let
          flake = builtins.getFlake \"path:$repo\";
          pkgs = import flake.inputs.nixpkgs {
            system = \"x86_64-linux\";
            overlays = [ flake.overlays.default ];
          };
        in pkgs.$pkg
      "
      return $status
    end

    # Convert a Fish array to a JSON array string
    function to_json_array
      if test (count $argv) -eq 0
        echo "[]"
        return
      end
      set -l items
      for item in $argv
        set -a items "\"$item\""
      end
      echo "["(string join "," $items)"]"
    end
  '';

  # ── Pipeline Script Generator ─────────────────────────────────
  #
  # Creates a single Fish script for the entire pipeline lifecycle.
  # Handles git sync, per-package updates, cache checks, builds,
  # git commit/push, and Discord notifications.
  #
  mkPipelineScript =
    {
      name,
      repoPath,
      branch,
      packages, # List of { name, updateScript? }
    }:
    let
      # All package names as a space-separated Fish list
      packageNames = lib.concatMapStringsSep " " (pkg: pkg.name) packages;

      # ── Nix-time generation of per-package update blocks ──
      # Each updateScript is written to its own store-path file to avoid
      # shell quoting issues (scripts may contain single/double quotes).
      # Bin paths that update scripts may need (prepended to PATH in wrappers
      # so child Fish processes find them even if user config resets PATH)
      updatePath = lib.makeBinPath [
        pkgs.nix
        pkgs.git
        pkgs.jq
        pkgs.curl
        pkgs.coreutils
        pkgs.nix-prefetch-git
      ];

      updatePhase = lib.concatMapStringsSep "\n" (
        pkg:
        if (pkg ? updateScript && pkg.updateScript != null) then
          let
            updateFile = pkgs.writeTextFile {
              name = "${name}-update-${builtins.replaceStrings [ "." ] [ "-" ] pkg.name}.fish";
              executable = true;
              text = ''
                #!${fish}
                set -gx PATH ${updatePath} $PATH
                cd "${repoPath}"; or exit 1
                ${pkg.updateScript}
              '';
            };
          in
          ''
            log "Running update for ${pkg.name}..."
            ${updateFile}; or begin
              log_error "Update script failed for ${pkg.name}"
              set -a update_failed "${pkg.name}"
            end
          ''
        else
          ''
            log "No update script for ${pkg.name}"
          ''
      ) packages;
    in
    pkgs.writeTextFile {
      name = "${name}-pipeline.fish";
      executable = true;
      text = ''
        #!${fish}
        #
        # ${name} — Build Pipeline
        # Auto-generated by mkPipeline — do not edit manually
        #
        # Lifecycle:
        #   1. Setup & validate
        #   2. Git sync (fetch + pull)
        #   3. Per-package update scripts + cache checks
        #   4. Build missing packages
        #   5. Git commit + push (if flake.lock changed)
        #   6. Send summary notification
        #

        set -g log_tag "${name}"

        ${sharedFishFunctions}

        #───────────────────────────────────────────────────────────────
        # Phase 0: Setup
        #───────────────────────────────────────────────────────────────

        set -g repo_path "${repoPath}"
        set -g state_dir "/var/lib/${stateBase}"
        set -g branch "${branch}"

        mkdir -p "$state_dir"

        if not test -d "$repo_path"
          log_error "Repository not found: $repo_path"
          exit 1
        end

        cd "$repo_path"; or begin
          log_error "Failed to cd to $repo_path"
          exit 1
        end

        log "Starting pipeline..."

        #───────────────────────────────────────────────────────────────
        # Phase 0.5: Git Sync
        #───────────────────────────────────────────────────────────────

        log "Syncing repository..."

        git fetch origin; or begin
          log_error "Failed to fetch from origin"
          notify "## ❌ ${name} Error
        > Failed to fetch from origin"
          exit 1
        end

        git pull --ff-only origin $branch; or begin
          log_error "Failed to pull (non-fast-forward?)"
          notify "## ❌ ${name} Error
        > Failed to pull from origin (non-fast-forward?)"
          exit 1
        end

        #───────────────────────────────────────────────────────────────
        # Phase 1: Update Scripts + Cache Check
        #───────────────────────────────────────────────────────────────

        # Tracking arrays
        set -g all_packages ${packageNames}
        set -g needs_build
        set -g cached
        set -g update_failed

        # ── Per-package update scripts (generated at Nix eval time) ──
        ${updatePhase}

        # ── Cache check (Fish loop over all packages) ──
        log "Checking package cache..."

        for pkg in $all_packages
          if pkg_in_cache "$repo_path" $pkg
            log "Package $pkg is in cache"
            set -a cached $pkg
          else
            log "Package $pkg is NOT in cache — needs build"
            set -a needs_build $pkg
          end
        end

        #───────────────────────────────────────────────────────────────
        # Decision: Early exit if nothing to build
        #───────────────────────────────────────────────────────────────

        if test (count $needs_build) -eq 0
          log "All packages up to date and in cache, nothing to build"

          # Still commit + push if update scripts changed anything
          if not git diff --quiet 2>/dev/null
            log "Committing changes (no builds needed)..."
            git add flake.lock '*.json'
            git commit -m "chore(${name}): update (all cached)

        Auto-updated by ${name} pipeline — no builds required"
            git push origin $branch; or begin
              log_error "Failed to push flake.lock update"
            end
          end

          exit 0
        end

        #───────────────────────────────────────────────────────────────
        # Start Notification
        #───────────────────────────────────────────────────────────────

        set -l start_lines
        set -a start_lines "## 🔨 ${name} Starting"
        set -a start_lines "> **Building:**"
        for pkg in $needs_build
          set -a start_lines "> • $pkg"
        end
        notify (string join \n $start_lines | string collect)

        #───────────────────────────────────────────────────────────────
        # Phase 2: Build
        #───────────────────────────────────────────────────────────────

        set -g built
        set -g failed

        log "Building packages..."

        for pkg in $needs_build
          log "Building $pkg..."
          if build_pkg "$repo_path" $pkg
            log "Successfully built $pkg"
            set -a built $pkg
          else
            log_error "Failed to build $pkg"
            set -a failed $pkg
          end
        end

        #───────────────────────────────────────────────────────────────
        # Git Commit + Push
        #───────────────────────────────────────────────────────────────

        if not git diff --quiet 2>/dev/null
          log "Committing changes..."
          git add flake.lock '*.json'

          set -l built_str (string join ", " $built)
          git commit -m "chore(${name}): build update

        Auto-updated by ${name} pipeline
        Built: $built_str"

          log "Pushing to origin..."
          git push origin $branch; or begin
            log_error "Failed to push to origin"
            notify "## ❌ ${name} Error
        > Built packages but failed to push to origin"
            exit 1
          end
        else
          log "No changes to commit"
        end

        #───────────────────────────────────────────────────────────────
        # End Notification
        #───────────────────────────────────────────────────────────────

        set -l lines
        set -a lines "## 🔨 ${name} Complete"

        if test (count $built) -gt 0
          set -a lines "> ✅ **Built:**"
          for pkg in $built
            set -a lines "> • $pkg"
          end
        end

        if test (count $failed) -gt 0
          set -a lines "> ❌ **Failed:**"
          for pkg in $failed
            set -a lines "> • $pkg"
          end
        end

        if test (count $cached) -gt 0
          set -a lines "> ⏭️ **Cached:**"
          for pkg in $cached
            set -a lines "> • $pkg"
          end
        end

        if test (count $update_failed) -gt 0
          set -a lines "> ⚠️ **Update failed:**"
          for pkg in $update_failed
            set -a lines "> • $pkg"
          end
        end

        set -a lines ">"
        set -a lines "> 📝 Run: \`nix flake update mix-nix\` in dot.nix"

        notify (string join \n $lines | string collect)

        #───────────────────────────────────────────────────────────────
        # Status JSON
        #───────────────────────────────────────────────────────────────

        set -l built_json (to_json_array $built)
        set -l failed_json (to_json_array $failed)
        set -l cached_json (to_json_array $cached)
        set -l update_failed_json (to_json_array $update_failed)

        echo "{\"status\":\"completed\",\"built\":$built_json,\"failed\":$failed_json,\"cached\":$cached_json,\"update_failed\":$update_failed_json}" \
          > "$state_dir/pipeline-status.json"

        log "Pipeline complete."

        #───────────────────────────────────────────────────────────────
        # Exit Code
        #───────────────────────────────────────────────────────────────

        if test (count $failed) -gt 0
          exit 1
        end
      '';
    };

  # ── Shared Systemd Service Configuration ──────────────────────
  #
  # Common service settings shared by all pipeline services.
  #
  mkServiceConfig =
    {
      svcName,
      script,
      repoPath,
      timeout,
    }:
    {
      path = with pkgs; [
        fish
        git
        nix
        jq
        apprise
        openssh
        coreutils
        curl
      ];

      environment = {
        HOME = "/home/${serviceUser}";
        NIX_PATH = "nixpkgs=${pkgs.path}";
        GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new";
      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}";
        User = serviceUser;
        Group = "ryot";
        WorkingDirectory = repoPath;
        TimeoutStartSec = timeout;

        # Shared state directory for status JSON files
        StateDirectory = stateBase;
        StateDirectoryMode = "0755";

        # Logging
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = svcName;

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          repoPath
          "/nix/var"
          "/home/${serviceUser}/.ssh" # SSH needs to write known_hosts
        ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
      };
    };

in
{
  # ── Main Factory Function ─────────────────────────────────────
  #
  # Returns a NixOS config attrset with:
  #   - systemd.services.<name>    (pipeline service)
  #   - systemd.timers.<name>      (single timer)
  #   - environment.systemPackages (required tools)
  #
  mkPipeline =
    {
      name,
      description ? "${name} Build Pipeline",
      repoPath,
      branch ? "main",
      schedule,
      timeout ? "10h",
      packages, # List of { name, updateScript? }
    }:
    let
      pipelineScript = mkPipelineScript {
        inherit
          name
          repoPath
          branch
          packages
          ;
      };
    in
    {
      systemd.services.${name} =
        (mkServiceConfig {
          svcName = name;
          script = pipelineScript;
          inherit repoPath timeout;
        })
        // {
          inherit description;
        };

      systemd.timers.${name} = {
        description = "Timer for ${description}";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = schedule;
          Persistent = true;
          RandomizedDelaySec = "15min";
        };
      };

      environment.systemPackages = [
        pkgs.apprise
        pkgs.jq
      ];
    };
}
