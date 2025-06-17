{
  config,
  lib,
  ...
}:

{
  services.backup = {
    enable = true;
    notificationUrl = lib.custom.mkAppriseUrl config.secretsSpec.users.admin.smtp "relay@ryot.foo";
    enableChainTimer = true;
    chainSchedule = "*-*-* 03:00:00";

    # Maintenance jobs run first
    maintenanceJobs = [
      {
        name = "snapraid";
        title = "SnapRAID";
        service = "snapraid-aio.service";
        logPattern = "SnapRAID-*.out";
        logPath = "/var/log/snapraid";
      }
    ];

    # Backup jobs run after maintenance
    jobs = [
      {
        name = "forgejo";
        title = "Forgejo";
        repo = "/pool/Backups/forgejo";
        sourcePath = "/pool/forgejo";
        verbose = true;
      }
      {
        name = "docker-storage";
        title = "Docker Storage";
        repo = "/pool/Backups/DockerStorage";
        sourcePath = "/mnt/drive1/DockerStorage";
        verbose = true;
      }
    ];
  };
}
