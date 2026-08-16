{
  config,
  gpu,
  host,
  lib,
  pkgs,
  ...
}:
let
  runtimeDir = "/run/user/${toString config.users.users.${host.user.name}.uid}";
  wayscope = config.home-manager.users.${host.user.name}.programs.wayscope.wrappers;
  heroicWayscope = lib.getExe wayscope.heroic.wrappedPackage;
  steamWayscope = lib.getExe wayscope.steam-wayscope.wrappedPackage;
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  systemdRun = lib.getExe' pkgs.systemd "systemd-run";

  sunshineGames = pkgs.writeTextFile {
    name = "sunshine-games";
    destination = "/bin/sunshine-games";
    executable = true;
    text = ''
      #!${lib.getExe pkgs.fish}

      set --global --export XDG_RUNTIME_DIR ${runtimeDir}
      set --global --export DBUS_SESSION_BUS_ADDRESS unix:path=$XDG_RUNTIME_DIR/bus

      switch $argv[1]
        case heroic-start
          ${systemdRun} --user --unit sunshine-heroic --collect ${heroicWayscope} --console
        case heroic-stop
          ${systemctl} --user stop sunshine-heroic.service; or true
        case steam-start
          ${systemdRun} --user --unit sunshine-steam --collect ${steamWayscope}
        case steam-stop
          ${systemctl} --user stop sunshine-steam.service; or true
      end
    '';
  };
  sunshineGamesCommand = "${sunshineGames}/bin/sunshine-games";
  mkPrepCmd = game: [
    {
      do = "${sunshineGamesCommand} ${game}-start";
      undo = "${sunshineGamesCommand} ${game}-stop";
    }
  ];
in
{
  users.users.${host.user.name}.extraGroups = [ "uinput" ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override { cudaSupport = true; };

    settings = {
      sunshine_name = "meowl";
      csrf_allowed_origins = "https://meowl:47990,https://meowl.ryot.local:47990,https://10.2.2.142:47990,https://10.2.2.5:47990";
      capture = "kms";
      encoder = "nvenc";
      adapter_name = "/dev/dri/by-path/pci-${gpu.pciAddress}-render";
      av1_mode = "0";
      system_tray = "disabled";
    };

    applications.apps = [
      {
        name = "Desktop";
        image-path = "desktop.png";
      }
      {
        name = "Steam Big Picture";
        image-path = "steam.png";
        prep-cmd = mkPrepCmd "steam";
      }
      {
        name = "Heroic Console";
        prep-cmd = mkPrepCmd "heroic";
      }
    ];
  };
}
