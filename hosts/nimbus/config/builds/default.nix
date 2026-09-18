{
  lib,
  pkgs,
  secrets,
  host,
  ...
}:
let
  user = host.user.name;
  mixRepo = "/repo/Nix/mix.nix";
  dotRepo = "/repo/Nix/dot.nix";
  # --no-config: NixOS ships /etc/fish/nixos-env-preinit.fish, which re-sources the
  # system environment and overwrites PATH unless __NIXOS_SET_ENVIRONMENT_DONE is set.
  # That silently discards the unit's `path`, so every helper below resolves to nothing.
  lockPublisher = pkgs.writeScriptBin "lock-publisher" ''
    #!${lib.getExe pkgs.fish} --no-config
    ${builtins.readFile ./lock-publisher.fish}
  '';
  builder = pkgs.writeScript "build-hosts.fish" ''
    #!${lib.getExe pkgs.fish} --no-config
    ${builtins.readFile ./build-hosts.fish}
  '';
in
{
  # Build the working trees without pulling, deploying, or staging user files.
  # Run manually: systemctl start host-builder; journalctl -u host-builder
  systemd.services.host-builder = {
    description = "Update locks and cache NixOS host builds";
    unitConfig.RequiresMountsFor = [
      mixRepo
      dotRepo
    ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = with pkgs; [
      fish
      git
      nix
      jq
      coreutils
      util-linux
      openssh
      apprise
      lockPublisher
    ];
    environment = {
      HOME = "/home/${user}";
      HOST_BUILD_STATE = "/var/lib/host-builder";
      HOST_BUILD_SYSTEM = pkgs.stdenv.hostPlatform.system;
      # Throwaway/loaner hosts: nothing consumes their closures from the cache.
      HOST_BUILD_SKIP = "meowl vm";
      HOST_BUILD_MIX_REPO = mixRepo;
      HOST_BUILD_DOT_REPO = dotRepo;
      HOST_BUILD_NOTIFY_URL = "${secrets.service.discord.lenix}?avatar=no&footer=no";
      GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new";
      GIT_TERMINAL_PROMPT = "0";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = builder;
      # Retire package-era roots only after all replacement host roots exist.
      ExecStartPost = "${pkgs.coreutils}/bin/rm -rf -- /var/lib/mix-builder/roots";
      User = user;
      Group = "ryot";
      WorkingDirectory = dotRepo;
      TimeoutStartSec = "16h";
      StateDirectory = "host-builder";
      StateDirectoryMode = "0700";
      UMask = "0077";
      Nice = 19;
      IOSchedulingClass = "idle";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        mixRepo
        dotRepo
        "/nix/var"
        "/home/${user}/.ssh"
        # Retire old package roots only after replacement host roots exist.
        "-/var/lib/mix-builder"
      ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };
  };

  systemd.timers.host-builder = {
    description = "Build and cache hosts nightly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
      RandomizedDelaySec = "2h";
    };
  };
}
