{ config, pkgs, ... }:

{
  # The Nextcloud admin password is stored in a separate file to avoid
  environment.etc."nextcloud-admin-pass".text = builtins.readFile ./nextcloud-admin-pass;

  services.nextcloud = { 
    enable = true;
    hostName = "cloud.ryot.foo";

    # Need to manually increment with every major upgrade.
    package = pkgs.nextcloud29;

    # Let NixOS install and configure the database automatically.
    database.createLocally = true;

    # Let NixOS install and configure Redis caching automatically.
    configureRedis = true;

    # Increase the maximum file upload size to avoid problems uploading videos.
    maxUploadSize = "5G";
    https = true;

    autoUpdateApps.enable = true;
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
      inherit calendar contacts mail notes tasks registration spreed twofactor_nextcloud_notification;

      # Custom app installation example.
      # cookbook = pkgs.fetchNextcloudApp rec {
      #   url =
      #     "https://github.com/nextcloud/cookbook/releases/download/v0.10.2/Cookbook-0.10.2.tar.gz";
      #   sha256 = "sha256-XgBwUr26qW6wvqhrnhhhhcN4wkI+eXDHnNSm1HDbP6M=";
      # };
    };

    settings = {
      overwriteProtocol = "https";
      overwritehost = "cloud.ryot.foo";
      trusted_domains = [ "cloud.ryot.foo" ];
      default_phone_region = "US";
    };

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass";
    };
  };
}