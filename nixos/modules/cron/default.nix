{
    services.cron = {
        enable = true;
        systemCronJobs = [
        # Runs snapraid-runner every day at 3am
        "0 3 * * *      root    snapraid-runner"
        # Runs a backup of the Docker storage directory every Monday at 4am
        "0 4 * * 0      root    tar -Pzcf /pool/Backups/DockerStorage/DockerStorage.tar.gz -C /mnt/drive1/DockerStorage ."
        ];
    };
}