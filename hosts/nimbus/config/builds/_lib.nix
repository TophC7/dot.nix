# Build Pipeline Factory
#
# Generates a systemd orchestrator + per-package build services from
# group-based package declarations.
#
# Architecture:
#   Timer → Orchestrator (git sync → group updates → pkg updates → cache check)
#     └─ Per-package build services (started on-demand via sudo systemctl start)
#
# Groups organize packages by source repository. Each group declares:
#   - A git repo to sync/commit
#   - A group-level update command (runs once)
#   - A default expression generator (mkExpr)
#   - A list of packages
#
# Usage:
#   builds.mkPipeline {
#     name = "mix-builder";
#     schedule = "Mon *-*-* 02:00:00";
#     groups = [
#       { name = "mix"; repo = mixRepo; update = "bonk update -p ${mixRepo}";
#         mkExpr = overlay; packages = [ { name = "linux-ryot"; } ]; }
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
  # ── Shared Config ───────────────────────────────────────────────
  serviceUser = host.user.name;
  appriseUrl = "${secrets.service.discord.lenix}?avatar=no&footer=no";

  nix = lib.getExe pkgs.nix;
  fish = lib.getExe pkgs.fish;
  apprise = lib.getExe pkgs.apprise;

  sanitizeName = name: builtins.replaceStrings [ "-" "." ] [ "_" "_" ] name;

  # Service name for a package's build unit
  buildSvcName =
    pipelineName: pkg: "${pipelineName}-build-${builtins.replaceStrings [ "." ] [ "-" ] pkg.name}";

  # ── Expression File Generator ───────────────────────────────────
  # Each package gets a .nix file in the store that evaluates to its derivation.
  mkExprFile =
    pipelineName: group: pkg:
    let
      expr = if pkg ? expr then pkg.expr else group.mkExpr pkg.name;
    in
    pkgs.writeText "${buildSvcName pipelineName pkg}-expr.nix" expr;

  # ── Per-Package Build Service Generator ─────────────────────────
  mkBuildService =
    pipelineName: group: pkg:
    let
      exprFile = mkExprFile pipelineName group pkg;
      svcName = buildSvcName pipelineName pkg;
    in
    {
      name = svcName;
      value = {
        description = "Build ${pkg.name}";
        path = with pkgs; [
          nix-output-monitor
          nix
          git
          coreutils
        ];
        environment = {
          HOME = "/home/${serviceUser}";
          NIX_PATH = "nixpkgs=${pkgs.path}";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "build-${builtins.replaceStrings [ "." ] [ "-" ] pkg.name}" ''
            exec ${nix} --option max-jobs 1 --option cores 10 build --impure --no-link -L --expr "import ${exprFile}"
          '';
          User = serviceUser;
          Group = "ryot";
          TimeoutStartSec = "4h";
          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = svcName;
          Nice = 19;
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;

          # Hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ReadWritePaths = [
            group.repo
            "/nix/var"
          ];
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
        };
        # NOT in wantedBy — started on-demand by orchestrator
      };
    };

  # ── Orchestrator Script Generator ───────────────────────────────
  mkOrchestratorScript =
    {
      name,
      branch,
      notifyHint,
      groups,
    }:
    let
      # Flatten all packages across groups (with group context)
      allPkgs = lib.concatMap (
        g:
        map (pkg: {
          inherit (pkg) name;
          group = g;
          inherit pkg;
        }) g.packages
      ) groups;

      allPkgNames = lib.concatMapStringsSep " " (p: p.name) allPkgs;
      allRepos = lib.unique (map (g: g.repo) groups);
      reposList = lib.concatStringsSep " " allRepos;

      # Per-package expression file mappings
      exprFileAssignments = lib.concatMapStringsSep "\n" (
        p:
        let
          exprFile = mkExprFile name p.group p.pkg;
        in
        "set -g expr_file_${sanitizeName p.name} ${exprFile}"
      ) allPkgs;

      # Per-package updater mappings (only for packages with update)
      updatePath = lib.makeBinPath [
        pkgs.nix
        pkgs.git
        pkgs.jq
        pkgs.curl
        pkgs.coreutils
        pkgs.nix-prefetch-git
      ];

      updaterAssignments = lib.concatMapStringsSep "\n" (
        p:
        if p.pkg ? update && p.pkg.update != null then
          let
            updateFile = pkgs.writeTextFile {
              name = "${name}-update-${builtins.replaceStrings [ "." ] [ "-" ] p.name}.fish";
              executable = true;
              text = ''
                #!${fish}
                set -gx PATH ${updatePath} $PATH
                cd "${p.group.repo}"; or exit 1
                ${p.pkg.update}
              '';
            };
          in
          "set -g updater_${sanitizeName p.name} ${updateFile}"
        else
          ""
      ) allPkgs;

      # Group update scripts (one per group)
      groupUpdateAssignments = lib.concatMapStringsSep "\n" (
        g:
        let
          updateFile = pkgs.writeTextFile {
            name = "${name}-group-update-${g.name}.fish";
            executable = true;
            text = ''
              #!${fish}
              set -gx PATH ${updatePath} $PATH
              cd "${g.repo}"; or exit 1
              ${g.update}
            '';
          };
        in
        "set -g group_update_${sanitizeName g.name} ${updateFile}"
      ) groups;

      groupNames = lib.concatMapStringsSep " " (g: g.name) groups;

      # Build service name mappings (for sudo systemctl start)
      buildSvcAssignments = lib.concatMapStringsSep "\n" (
        p: "set -g build_svc_${sanitizeName p.name} ${buildSvcName name p.pkg}"
      ) allPkgs;
    in
    pkgs.writeTextFile {
      name = "${name}-orchestrator.fish";
      executable = true;
      text = ''
        #!${fish}
        #
        # ${name} — Build Orchestrator
        # Auto-generated by mkPipeline
        #

        set -g log_tag "${name}"

        # ── Helper functions ──────────────────────────────────────

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

        function resolve_expr_file
          set -l sanitized (string replace -a '-' '_' -- $argv[1] | string replace -a '.' '_')
          echo (eval echo \$expr_file_$sanitized)
        end

        function pkg_in_cache
          set -l expr_file (resolve_expr_file $argv[1])
          ${nix} path-info --impure --expr "import $expr_file" >/dev/null 2>&1
          return $status
        end

        function resolve_updater
          set -l sanitized (string replace -a '-' '_' -- $argv[1] | string replace -a '.' '_')
          set -l var_name "updater_$sanitized"
          if set -q $var_name
            echo $$var_name
          end
        end

        function resolve_build_svc
          set -l sanitized (string replace -a '-' '_' -- $argv[1] | string replace -a '.' '_')
          echo (eval echo \$build_svc_$sanitized)
        end

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

        # ── Variable mappings (generated at NixOS eval time) ──────

        ${exprFileAssignments}
        ${updaterAssignments}
        ${groupUpdateAssignments}
        ${buildSvcAssignments}

        # ── Setup ─────────────────────────────────────────────────

        set -g all_repos ${reposList}
        set -g all_groups ${groupNames}
        set -g all_packages ${allPkgNames}
        set -g state_dir "/var/lib/${name}"
        set -g branch "${branch}"

        set -g needs_build
        set -g cached
        set -g built
        set -g failed
        set -g update_failed

        mkdir -p "$state_dir"

        for repo in $all_repos
          if not test -d "$repo"
            log_error "Repository not found: $repo"
            exit 1
          end
        end

        log "Starting pipeline..."

        #───────────────────────────────────────────────────────────
        # Phase 1: Git Sync
        #───────────────────────────────────────────────────────────

        for repo in $all_repos
          log "Syncing $repo..."
          cd "$repo"; or begin
            log_error "Failed to cd to $repo"
            exit 1
          end
          git fetch origin; or begin
            log_error "Failed to fetch from origin in $repo"
            notify "## ❌ ${name} Error
        > Failed to fetch from origin in $repo"
            exit 1
          end
          git pull --ff-only origin $branch; or begin
            log_error "Failed to pull in $repo (non-fast-forward?)"
            notify "## ❌ ${name} Error
        > Failed to pull in $repo (non-fast-forward?)"
            exit 1
          end
        end

        #───────────────────────────────────────────────────────────
        # Phase 2: Group Updates (once per group)
        #───────────────────────────────────────────────────────────

        for group in $all_groups
          set -l sanitized (string replace -a '-' '_' -- $group | string replace -a '.' '_')
          set -l var_name "group_update_$sanitized"
          set -l update_script $$var_name

          log "Running group update: $group..."
          $update_script; or begin
            log_error "Group update failed: $group"
            set -a update_failed "group:$group"
          end
        end

        #───────────────────────────────────────────────────────────
        # Phase 3: Per-Package Updates + Cache Check
        #───────────────────────────────────────────────────────────

        for pkg in $all_packages
          # Per-package update (if defined)
          set -l updater (resolve_updater $pkg)
          if test -n "$updater"
            log "Running update for $pkg..."
            $updater; or begin
              log_error "Update failed for $pkg"
              set -a update_failed $pkg
            end
          end

          # Cache check
          if pkg_in_cache $pkg
            log "Cached: $pkg"
            set -a cached $pkg
          else
            log "Needs build: $pkg"
            set -a needs_build $pkg
          end
        end

        #───────────────────────────────────────────────────────────
        # Early Exit
        #───────────────────────────────────────────────────────────

        if test (count $needs_build) -eq 0
          log "All packages cached, nothing to build"

          for repo in $all_repos
            cd "$repo"
            if not git diff --quiet 2>/dev/null
              log "Committing updates in $repo..."
              git add flake.lock '*.json'
              git commit -m "chore(${name}): update (all cached)

        Auto-updated by ${name} pipeline — no builds required"
              git push origin $branch; or log_error "Failed to push $repo"
            end
          end
          exit 0
        end

        #───────────────────────────────────────────────────────────
        # Start Notification
        #───────────────────────────────────────────────────────────

        set -l start_lines
        set -a start_lines "## 🔨 ${name} Starting"
        set -a start_lines "> **Building:**"
        for pkg in $needs_build
          set -a start_lines "> • $pkg"
        end
        notify (string join \n $start_lines | string collect)

        #───────────────────────────────────────────────────────────
        # Phase 4: Build (via child services)
        #───────────────────────────────────────────────────────────

        log "Building packages..."

        for pkg in $needs_build
          set -l svc (resolve_build_svc $pkg)
          log "Starting $svc..."

          if sudo systemctl start "$svc"
            log "Built: $pkg"
            set -a built $pkg
          else
            log_error "Failed: $pkg (see: journalctl -u $svc)"
            set -a failed $pkg
          end
        end

        #───────────────────────────────────────────────────────────
        # Phase 5: Git Commit + Push
        #───────────────────────────────────────────────────────────

        set -l built_str (string join ", " $built)

        for repo in $all_repos
          cd "$repo"
          if not git diff --quiet 2>/dev/null
            log "Committing changes in $repo..."
            git add flake.lock '*.json'
            git commit -m "chore(${name}): build update

        Auto-updated by ${name} pipeline
        Built: $built_str"
            log "Pushing $repo..."
            git push origin $branch; or begin
              log_error "Failed to push $repo"
              notify "## ❌ ${name} Error
        > Built packages but failed to push $repo"
              exit 1
            end
          else
            log "No changes in $repo"
          end
        end

        #───────────────────────────────────────────────────────────
        # Phase 6: Notify
        #───────────────────────────────────────────────────────────

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
        set -a lines "> ${notifyHint}"

        notify (string join \n $lines | string collect)

        #───────────────────────────────────────────────────────────
        # Status JSON + Exit
        #───────────────────────────────────────────────────────────

        echo "{\"status\":\"completed\",\"built\":$(to_json_array $built),\"failed\":$(to_json_array $failed),\"cached\":$(to_json_array $cached),\"update_failed\":$(to_json_array $update_failed)}" \
          > "$state_dir/pipeline-status.json"

        log "Pipeline complete."

        if test (count $failed) -gt 0
          exit 1
        end
      '';
    };

in
{
  mkPipeline =
    {
      name,
      description ? "${name} Build Pipeline",
      branch ? "main",
      schedule,
      timeout ? "14h",
      notifyHint ? "📝 Pipeline complete",
      groups, # List of { name, repo, update, mkExpr, packages }
    }:
    let
      # Flatten all packages with group context
      allPkgs = lib.concatMap (
        g:
        map (pkg: {
          inherit (pkg) name;
          group = g;
          inherit pkg;
        }) g.packages
      ) groups;

      allRepos = lib.unique (map (g: g.repo) groups);

      orchestratorScript = mkOrchestratorScript {
        inherit
          name
          branch
          notifyHint
          groups
          ;
      };

      # Generate per-package build services
      buildServices = builtins.listToAttrs (map (p: mkBuildService name p.group p.pkg) allPkgs);
    in
    {
      systemd.services = buildServices // {
        ${name} = {
          inherit description;
          path = with pkgs; [
            fish
            git
            nix
            jq
            apprise
            openssh
            coreutils
            curl
            sudo
          ];
          environment = {
            HOME = "/home/${serviceUser}";
            NIX_PATH = "nixpkgs=${pkgs.path}";
            GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new";
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${orchestratorScript}";
            User = serviceUser;
            Group = "ryot";
            WorkingDirectory = builtins.head allRepos;
            TimeoutStartSec = timeout;
            StateDirectory = name;
            StateDirectoryMode = "0755";
            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = name;
            Nice = 19;
            IOSchedulingClass = "idle";
            IOSchedulingPriority = 7;

            # Lighter hardening (needs sudo access for systemctl)
            NoNewPrivileges = false; # Required for sudo
            PrivateTmp = true;
            ProtectSystem = "strict";
            ReadWritePaths = allRepos ++ [
              "/nix/var"
              "/home/${serviceUser}/.ssh"
            ];
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
          };
        };
      };

      systemd.timers.${name} = {
        description = "Timer for ${description}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = schedule;
          Persistent = true;
          RandomizedDelaySec = "2h";
        };
      };

      # Sudo rule: allow orchestrator user to start build services
      security.sudo.extraRules = [
        {
          users = [ serviceUser ];
          commands = [
            {
              command = "/run/current-system/sw/bin/systemctl start ${name}-build-*";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      environment.systemPackages = [
        pkgs.apprise
        pkgs.jq
      ];
    };
}
