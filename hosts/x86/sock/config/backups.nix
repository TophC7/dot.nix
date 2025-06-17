{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.backup = {
    enable = true;
    notificationUrl = lib.custom.mkAppriseUrl config.secretsSpec.users.admin.smtp "relay@ryot.foo";
    enableChainTimer = true;

    jobs = [
      {
        name = "ochre-storage";
        title = "Ochre Storage";
        repo = "/pool/Backups/OchreStorage";
        sourcePath = "/OchreStorage";
      }
    ];
  };
}
