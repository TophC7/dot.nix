{
  pkgs,
  inputs,
  config,
  ...
}:
let

  apprise-url = config.secretsSpec.users.admin.smtp.notifyUrl;

  snapraid-aio = inputs.snapraid-aio.nixosModules.default;
  snapraid-aio-config = pkgs.writeTextFile {
    name = "snapraid-aio.config";
    text = ''
      CONFIG_VERSION="3.4"
      CHECK_UPDATES=1

      # Notification settings
      APPRISE=0
      APPRISE_URL=""
      APPRISE_ATTACH=1
      APPRISE_BIN="${pkgs.apprise}/bin/apprise"
      APPRISE_EMAIL=1
      APPRISE_EMAIL_URL="${apprise-url}"
      TELEGRAM=0
      DISCORD=0

      # Thresholds for sync operations
      DEL_THRESHOLD=500
      UP_THRESHOLD=500
      IGNORE_PATTERN=""
      ADD_DEL_THRESHOLD=0
      SYNC_WARN_THRESHOLD=0

      # Scrub settings
      SCRUB_PERCENT=5
      SCRUB_AGE=10
      SCRUB_NEW=1
      SCRUB_DELAYED_RUN=0

      # Performance and behavior settings
      PREHASH=1
      FORCE_ZERO=0
      SPINDOWN=0
      VERBOSITY=1
      RETENTION_DAYS=30

      # Logging settings
      SNAPRAID_LOG_DIR="/var/log/snapraid"
      SMART_LOG=1
      SMART_LOG_NOTIFY=0
      SNAP_STATUS=1
      SNAP_STATUS_NOTIFY=1

      # Critical paths
      SNAPRAID_CONF="/etc/snapraid.conf"
      SNAPRAID_BIN="${pkgs.snapraid}/bin/snapraid"

      # Email settings (optional - uncomment and configure if needed)
      # EMAIL_ADDRESS="your-email@example.com"
      # FROM_EMAIL_ADDRESS="snapraid@your-server.com"

      # Advanced settings - typically no need to modify
      CHK_FAIL=0
      DO_SYNC=1
      EMAIL_SUBJECT_PREFIX="(SnapRAID on $(hostname))"
      SERVICES_STOPPED=0
      SYNC_WARN_FILE="/var/lib/snapraid-aio/snapRAID.warnCount"
      SCRUB_COUNT_FILE="/var/lib/snapraid-aio/snapRAID.scrubCount"
      TMP_OUTPUT="/var/lib/snapraid-aio/snapRAID.out"
      SNAPRAID_LOG="/var/log/snapraid/snapraid.log"
    '';
  };

  snapraid-conf = pkgs.writeTextFile {
    name = "snapraid.conf";
    text = ''
      ## /etc/snapraid.conf ##

      # Defines the file to use as parity storage
      parity /mnt/parity/snapraid.parity

      # Defines the files to use as content list
      content /var/snapraid.content
      content /mnt/drive1/snapraid.content
      content /mnt/drive2/snapraid.content
      content /mnt/drive3/snapraid.content
      content /mnt/parity/snapraid.content

      # Defines the data disks to use
      data d1 /mnt/drive1/
      data d2 /mnt/drive2/
      data d3 /mnt/drive3/

      # Defines files and directories to exclude
      exclude *.unrecoverable
      exclude /tmp/
      exclude /lost+found/
      exclude /var/tmp/
      exclude /var/cache/
      exclude /var/log/
      exclude .trash/
      exclude .Trash-1000/
      exclude .Trash/
      # These dirs change data all the time
      # so I back them up in borg repos that are not excluded 
      exclude /DockerStorage/
      exclude /data/forgejo/
      exclude /data/forgejo/
      exclude /data/forgejo/
    '';
  };
in
{
  imports = [
    inputs.snapraid-aio.nixosModules.default
  ];

  # Make sure the SnapRAID config exists
  environment.etc."snapraid.conf".source = snapraid-conf;

  # Create required directories
  systemd.tmpfiles.rules = [
    "d /var/lib/snapraid-aio 0755 root root -"
    "d /var/log/snapraid 0755 root root -"
  ];

  # Set up snapraid-aio service
  services.snapraid-aio = {
    enable = true;
    configFile = snapraid-aio-config;
    schedule = "*-*-* 04:00:00"; # Run daily at 3am
  };
}
