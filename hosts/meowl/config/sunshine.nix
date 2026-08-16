{
  config,
  gpus,
  host,
  lib,
  pkgs,
  ...
}:
let
  wayscope = config.home-manager.users.${host.user.name}.programs.wayscope.wrappers;
  steam = lib.getExe config.programs.steam.package;
  steamWayscope = lib.getExe wayscope.steam-wayscope.wrappedPackage;
  setsid = lib.getExe' pkgs.util-linux "setsid";
in
{
  users.users.${host.user.name}.extraGroups = [ "uinput" ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      sunshine_name = "meowl";
      csrf_allowed_origins = "https://meowl:47990,https://meowl.ryot.local:47990,https://10.2.2.142:47990,https://10.2.2.5:47990";
      capture = "kms";
      encoder = "vaapi";
      adapter_name = "/dev/dri/by-path/pci-${gpus.display}-render";
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
        prep-cmd = [
          {
            do = steamWayscope;
            undo = "${setsid} ${steam} steam://close/bigpicture";
          }
        ];
        image-path = "steam.png";
      }
      {
        name = "Heroic Console";
        cmd = lib.getExe wayscope.heroic-console.wrappedPackage;
      }
    ];
  };
}
