{ pkgs, ... }: {
  systemd.services.disable-hdd-sleep =
    { description = "Disable HDD sleep";
      after = [ "initrd-root-device.target" "local-fs-pre.target" "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
      before = [ "shutdown.target" ];
      requires = [ "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
      # bindsTo = [ "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
      script =
        ''
          ${pkgs.sdparm}/bin/sdparm --flexible -6 -l --set STANDBY_Z=0 \
            /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
        '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutSec = 0;
      };
      unitConfig = {
        # ConditionPathIsSymbolicLink = "/dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1";
        DefaultDependencies = "no";
        Conflicts = "shutdown.target";        
      };
      # wantedBy = [ "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
  };
}
