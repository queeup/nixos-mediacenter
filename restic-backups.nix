{ pkgs, ... }: {
  services.restic.backups = {
    immich-photos = {
      user = "user";
      repository = "/backups/restic/immich-photos";
      initialize = false;
      passwordFile = "/backups/resticPasswd";
      extraBackupArgs = [
        "--exclude-file=/backups/restic_immich-photos.exclude-file"
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-scan"
      ];
      paths = [ "/" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "21:30";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };

    immich-photos-second = {
      user = "user";
      repository = "/data/backups/restic/immich-photos";
      initialize = false;
      passwordFile = "/backups/resticPasswd";
      extraBackupArgs = [
        "--exclude-file=/backups/restic_immich-photos.exclude-file"
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-scan"
      ];
      paths = [ "/home/user/docker-compose/immich/data" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "21:50";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };

    immich-photos-gdrive = {
      user = "user";
      repository = "rclone:gdrive:Backups/restic/immich-photos";
      initialize = false;
      passwordFile = "/backups/resticPasswd";
      rcloneConfigFile = "/backups/rcloneConfig";
      extraBackupArgs = [
        "--exclude-file=/backups/restic_immich-photos.exclude-file"
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-scan"
      ];
      paths = [ "/home/user/docker-compose/immich/data" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "21:00";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
      backupPrepareCommand = ''
        ${pkgs.iputils}/bin/ping -q -n -c 1 drive.google.com > /dev/null
      '';
    };

    nixos-mediacenter = {
      user = "user";
      repository = "/backups/restic/nixos-mediacenter_M720q";
      initialize = false;
      passwordFile = "/backups/resticPasswd";
      extraBackupArgs = [
        "--exclude-file=/backups/restic_nixos-mediacenter.exclude-file"
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-scan"
      ];
      paths = [ "/" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "20:30";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };

    nixos-mediacenter-remote = {
      user = "user";
      repository = "rest:http://192.168.1.2:8000/nixos-mediacenter_M720q";
      initialize = false;
      passwordFile = "/backups/resticPasswd";
      extraBackupArgs = [
        "--exclude-file=/backups/restic_nixos-mediacenter.exclude-file"
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--tag=remote"
        "--no-scan"
      ];
      paths = [ "/" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "20:00";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
      backupPrepareCommand = ''
        ${pkgs.iputils}/bin/ping -q -n -c 1 192.168.1.2 > /dev/null
        ${pkgs.curl}/bin/curl --silent --head --fail -L http://192.168.1.2:8000/nixos-mediacenter_M720q/config > /dev/null
      '';
    };

    nixos-mediacenter-gdrive = {
      user = "user";
      repository = "rclone:gdrive:Backups/restic/nixos-mediacenter_M720q";
      initialize = false;
      passwordFile = "/backups/resticPasswd";
      rcloneConfigFile = "/backups/rcloneConfig";
      extraBackupArgs = [
        "--exclude-file=/backups/restic_nixos-mediacenter.exclude-file"
        "--exclude-if-present=.exclude_from_backup"
        "--tag=systemd.timer"
        "--no-scan"
      ];
      paths = [ "/" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
        "--keep-tag forever"
      ];
      timerConfig = {
        OnCalendar = "20:00";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
      backupPrepareCommand = ''
        ${pkgs.iputils}/bin/ping -q -n -c 1 drive.google.com > /dev/null
      '';
    };
  };
}
