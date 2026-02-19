{ config, lib, pkgs, ... }:

let
  nixos-hardware = builtins.fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
in
{
  imports = [
    # "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/common/gpu/intel"
    # (nixos-hardware + "/common/gpu/intel")
    ./filesystems.nix
    ./hardware-configuration.nix
    ./restic-backups.nix
    # ./systemd-services.nix
    ./unstable-pkgs.nix
    ./users.nix
  ];

  boot = {
    # kernelPackages = pkgs.linuxPackages_latest;  # https://nixos.wiki/wiki/Linux_kernel
    kernelParams = [
      "mitigations=off"
      "i915.enable_fbc=0"
      "i915.enable_guc=2"  # for intel-media-driver
      # "i915.guc_firmware_path=${pkgs.linux-firmware}/lib/firmware/i915/"
      "pcie_aspm=off"  # https://bbs.archlinux.org/viewtopic.php?pid=1183372#p1183372
                       # https://serverfault.com/questions/226319/what-does-pcie-aspm-do
                       # https://serverfault.com/a/219658
                       # https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Extreme_(Gen_2)#Ethernet
      "e1000e.SmartPowerDownEnable=0"
      "e1000e.EEE=0"  # Disable Energy Efficient Ethernet
      "usbcore.autosuspend=-1"  # for usb enclosure
      "ipv6.disable=1"
    ];
    kernel.sysctl = {
      # https://github.com/Prowlarr/Prowlarr/issues/1992#issuecomment-2482078462
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
      "net.ipv6.conf.lo.disable_ipv6" = 1;
    };
    # blacklistedKernelModules = [ "iTCO_wdt" ];  # https://wiki.archlinux.org/title/Improving_performance#Watchdogs
    # extraModprobeConfig = "options i915 enable_guc=2";
    # kernel.sysctl = { "vm.swappiness" = 10 };
    initrd.kernelModules = [ "i915" ];
    tmp = {
      cleanOnBoot = true;
      useTmpfs = true;
    };
    loader = {
      timeout = 2;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
    };
  };

  /*
  powerManagement.powerUpCommands = ''
    ${pkgs.hdparm}/sbin/hdparm -B 128 -M 128 -S 0 \
      /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
    ${pkgs.hdparm}/sbin/hdparm -S 0 \
     /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
    echo "Running powerUpCommand..."
    sleep 10
    DRIVE='/dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1'
    while [ ! -d "$DRIVE" ]; do
    	sleep 1
    done
    ${pkgs.sdparm}/bin/sdparm -l -a /dev/sda
    ${pkgs.sdparm}/bin/sdparm -l -a /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
    ${pkgs.sdparm}/bin/sdparm --flexible -6 -l --set STANDBY_Z=0 \
     /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
  '';
  */

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver  # iHD
        intel-compute-runtime  # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # priority = 20;
  };

  networking = {
    networkmanager.enable = true;
    hostName = "nixos-mediacenter";
    firewall.enable = false;
    enableIPv6 = false;
    # usePredictableInterfaceNames = false;  # disable Renaming network interfaces
                                             # https://nixos.org/manual/nixos/stable/#sec-rename-ifs
    networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "tsPerformance" ''
          # https://tailscale.com/kb/1320/performance-best-practices?q=ethtool#ethtool-configuration
          #NETDEV=$(${pkgs.iproute2}/bin/ip route show 0/0 | ${pkgs.coreutils}/bin/cut -f5 -d" ")
          #${pkgs.ethtool}/bin/ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
          # https://github.com/udf/nix-hanzo/blob/master/phanes/fragments/tailscale.nix
          if [ "$2" != "up" ]; then
            logger "exit: event $2 != up"
            exit
          fi

          ${lib.getExe pkgs.ethtool} -K $DEVICE_IFACE rx-udp-gro-forwarding on rx-gro-list off
        '';
      }
    ];
  };

  time.timeZone = "Europe/Istanbul";

  console = {
    keyMap = "trq";
  };

  security = {
    sudo.wheelNeedsPassword = false;
    # sudo.enable = false;
    # doas.enable = true;
    # doas.wheelNeedsPassword = false;
  };

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
    fstrim.enable = true;
    fwupd.enable = true;
    sshd.enable = true;
    openssh = {
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";
    };
    tailscale = {
      enable = true;
      extraUpFlags = [ "--ssh" "--advertise-routes=192.168.1.0/24,10.0.20.0/24" ];
    };
    # hints from https://dataswamp.org/~solene/2021-12-21-my-nixos.html
    cron.systemCronJobs = [
      "0 20 * * * root journalctl --vacuum-time=2d"  # clean logs older than 2d
      # "0 1 * * * root rtcwake -m mem --date +6h"  # auto standby
    ];
    # Automount USB disks.
    # hints from: https://wiki.archlinux.org/title/Udev#Mounting_drives_in_rules
    #             https://unix.stackexchange.com/a/657698
    #             man --pager="less -p ^EXAMPLE" systemd-mount
    udev.extraRules = ''
      # Disable HDD sleep
      ##ACTION=="add|change", 
      KERNEL=="sd[a-z]", ATTRS{queue/rotational}=="1", ENV{ID_FS_UUID}=="8b4e6bca-be8c-4314-b6ff-ce7cf59978a1", \
      #    RUN+="${pkgs.hdparm}/sbin/hdparm -S 0 /dev/%k"
          RUN+="${pkgs.sdparm}/bin/sdparm --flexible --save -6 --set STANDBY_Z=0 /dev/%k"
      # check for special partitions we dont want mount
      IMPORT{builtin}="blkid"
      ENV{ID_FS_LABEL}=="media*|backup|data", GOTO="exit"
      ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", \
          RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --automount=yes --collect --options=uid=1000,gid=100,user,umask=000 $devnode /media/'%E{ID_FS_LABEL}'"
      ACTION=="remove", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", \
          RUN{program}+="${pkgs.systemd}/bin/systemd-mount --umount --collect /media/'%E{ID_FS_LABEL}'", \
          RUN{program}+="${pkgs.coreutils-full}/bin/rmdir /media/'%E{ID_FS_LABEL}'"
      LABEL="exit"
    '';

    # Using networkmanager.dispatcherScripts instead of this.
    # if you use systemd-networkd use this.
    /*
    networkd-dispatcher = {
     enable = false;
     rules = {
       # https://tailscale.com/kb/1320/performance-best-practices?q=ethtool#ethtool-configuration
       "50-tailscale" = {
         onState = [ "routable" ];
         script = ''
           #!${pkgs.runtimeShell}
           NETDEV=$(${pkgs.iproute2}/bin/ip route show 0/0 | ${pkgs.coreutils}/bin/cut -f5 -d" ")
           ${pkgs.ethtool}/bin/ethtool -k $NETDEV | grep "rx-udp-gro-forwarding\|rx-gro-list"
           ${pkgs.ethtool}/bin/ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off || true
           ${pkgs.ethtool}/bin/ethtool -k $NETDEV | grep "rx-udp-gro-forwarding\|rx-gro-list"
         '';
       };
     };
    };
    */

    /*
    journald.extraConfig = ''
      RateLimitIntervalSec=30s
      RateLimitBurst=10000
    '';
    */

    /*
    k3s = {
      enable = true;
      extraFlags = "--write-kubeconfig-mode=644 --disable-cloud-controller --disable-helm-controller --disable metrics-server --disable servicelb --disable traefik --disable helm"
    }
    */
  };

  /*
  services.smartd = {
    enable = true;
    notifications.mail.enable = true;
    # notifications.test = true;
    # notifications.mail.recipient = "mysecretmail@gmail.com";
    notifications.wall.enable = false;
    devices = [
      {
        device = "DEVICESCAN";
        options = toString [
          "-a"
          "-o on"
          "-S on"
          "-n standby,q"
          "-W 4,43,50"
          "-m mysecretmail@gmail.com"
          "-M test"
          "-s (O/../.././09|S/../.././04|L/../../6/05)"
        ];
      }
    ];
  };
  */

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
      liveRestore = false;  # https://github.com/NixOS/nixpkgs/issues/182916
    };
    /*
    podman = {
      enable = true;
      dockerSocket.enable = true;
    };
    */
  };

  environment = {
    localBinInPath = true;
    etc = {
      "systemd/journald.conf.d/99-storage.conf".text = ''
        [Journal]
        Storage=volatile
        RuntimeMaxUse=100M
        RuntimeKeepFree=20M
      '';
    };
    shellAliases = {
      cat = "${pkgs.bat}/bin/bat --style=plain --pager=never";
      ls = "${pkgs.eza}/bin/eza --group-directories-first";
      ll = "${pkgs.eza}/bin/eza --all --long --group-directories-first --octal-permissions";
      # cp = "${pkgs.xcp}/bin/xcp";
      top = "${pkgs.bottom}/bin/btm";
      nano = "${pkgs.nano}/bin/nano -E -w -i";
      nn = "${pkgs.nano}/bin/nano -E -w -i";
      # sudo = "doas";
    };
    systemPackages = with pkgs; [
      xcp
      duf
      restic
    ];
  };

  documentation.enable = false;

  nix = {
    settings.auto-optimise-store = true;
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 14d";
  };

  system = {
    stateVersion = "25.11";
  };
}
