{ host, ... }:
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
      adapter_name = "/dev/dri/renderD128";
      av1_mode = "0";
      system_tray = "disabled";
    };
  };
}
