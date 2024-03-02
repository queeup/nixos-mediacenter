{ pkgs, ... }: {
  systemd.services.disable-hdd-sleep = {
    enable = false;
    description = "Disable HDD sleep";
    after = [ "initrd-root-device.target" "local-fs-pre.target" "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
    before = [ "shutdown.target" ];
    requires = [ "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
    # bindsTo = [ "dev-disk-by\x2duuid-8b4e6bca\x2dbe8c\x2d4314\x2db6ff\x2dce7cf59978a1.device" ];
    script =
      ''
        #!${pkgs.runtimeShell}
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

  systemd.services.issuegen-public-ipv4 = {
    enable = false;
    description = "Generate issue with public ipv4 address";
    before = [ "systemd-user-sessions.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    script =
      ''
        #!${pkgs.runtimeShell}
        if [ ! -d /etc/issue.d ]; then
          ${pkgs.coreutils-full}/bin/mkdir /etc/issue.d
        fi
        echo "Detected Public IPv4: is $(curl https://ipv4.icanhazip.com)" > \
          /etc/issue.d/50_public-ipv4.issue
      '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPost = "${pkgs.coreutils-full}/bin/touch /var/lib/issuegen-public-ipv4";
    };
    unitConfig = {
    #  ConditionPathIsSymbolicLink = "/dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1";
      DefaultDependencies = "no";
      ConditionPathExists = "!/var/lib/issuegen-public-ipv4";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
