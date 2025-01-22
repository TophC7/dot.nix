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

    # appstoreEnable = true;
    autoUpdateApps.enable = true;
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
      inherit
        calendar
        contacts
        mail
        notes
        tasks
        registration
        spreed
        twofactor_nextcloud_notification
        ;

      # breeze = pkgs.fetchNextcloudApp {
      #   sha256 = "sha256-9xMH9IcQrzzMJ5bL6RP/3CS1QGuByriCjGkJQJxQ4CU=";
      #   url = "https://github.com/mwalbeck/nextcloud-breeze-dark/releases/download/v29.0.0/breezedark.tar.gz";
      #   license = "agpl3Only";
      # };

      oidc_login = pkgs.fetchNextcloudApp {
        sha256 = "sha256-DrbaKENMz2QJfbDKCMrNGEZYpUEvtcsiqw9WnveaPZA=";
        url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.2.0/oidc_login.tar.gz";
        license = "agpl3Only";
      };

      impersonate = pkgs.fetchNextcloudApp {
        sha256 = "sha256-7NCfm2c861E1ZOZhpqjbsw2LC9I7ypp2J1LamqmWvtU=";
        url = "https://github.com/nextcloud-releases/impersonate/releases/download/v1.16.0/impersonate-v1.16.0.tar.gz";
        license = "agpl3Only";
      };

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
      allow_user_to_change_display_name = "false";
      lost_password_link = "disabled";
      oidc_login_provider_url = "https://auth.ryot.foo/application/o/cloud-slug";
      oidc_login_client_id = "Fmc7v4MFQ3Iv8bZwOdXIaqYZUdDkiL0bKbDuGWd3";
      oidc_login_client_secret = "TPo7Q4uiusak2G6cneZMijMt45Y2FNCE2YT4hXWU9IjcywNhgzFXDY5sxC4SyyggkFmj3Dz3DYcZj295kjAES2W140EfjNRWI6xHd6B7Fxj8B6BzudJ5ii5Um1ZyjU47";
      # oidc_login_logout_url = "https://openid.example.com/thankyou";
      # oidc_login_end_session_redirect = "false";
      oidc_login_button_text = "Authentik Login";
      oidc_login_scope = "openid profile";
      oidc_login_disable_registration = "false";
    };

    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass";
    };
  };
}
