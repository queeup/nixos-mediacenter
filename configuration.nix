{ config, pkgs, ... }: {
  imports = [
    # "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/common/gpu/intel"
    ./hardware-configuration.nix
    ./filesystems.nix
    ./users.nix
    ./unstable-pkgs.nix
    ./restic-backups.nix
    # ./systemd-services.nix
  ];

  boot = {
    # kernelPackages = pkgs.linuxPackages_latest;  # https://nixos.wiki/wiki/Linux_kernel
    kernelParams = [
      "mitigations=off"
      "i915.enable_fbc=1"
      "i915.enable_guc=2"  # for intel-media-driver
      # "i915.guc_firmware_path=${pkgs.linux-firmware}/lib/firmware/i915/"
      "pcie_aspm=off"  # https://bbs.archlinux.org/viewtopic.php?pid=1183372#p1183372
                       # https://serverfault.com/questions/226319/what-does-pcie-aspm-do
                       # https://serverfault.com/a/219658
      "usbcore.autosuspend=-1"  # for usb enclosure
    ];
    # blacklistedKernelModules = [ "iTCO_wdt" ];  # https://wiki.archlinux.org/title/Improving_performance#Watchdogs
    # extraModprobeConfig = "options i915 enable_guc=2";
    # kernel.sysctl = { "vm.swappiness" = 10 };
    initrd.kernelModules = [ "i915" ];
    readOnlyNixStore = true;
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

  # powerManagement.powerUpCommands = ''
  #   # Be aware, this is not working on usb disks.
  #   # Because this is triggered on Boot Stage 1.
  #   # ${pkgs.hdparm}/sbin/hdparm -B 128 -M 128 -S 0 \
  #   #   /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
  #   ${pkgs.sdparm}/bin/sdparm --flexible -q -6 -l --set STANDBY_Z=0 \
  #     /dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1
  # '';

  hardware = {
    cpu.intel.updateMicrocode = true;
    opengl = {
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
    fstrim.enable = true;
    fwupd.enable = true;
    sshd.enable = true;
    openssh = {
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";
    };
    tailscale = {
      enable = true;
      extraUpFlags = [ "--ssh" "--advertise-routes=192.168.1.0/24" ];
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
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTRS{queue/rotational}=="1", \
          RUN+="${pkgs.hdparm}/bin/hdparm -S 0 /dev/%k"
      # check for special partitions we dont want mount
      #IMPORT{builtin}="blkid"
      ENV{ID_FS_LABEL}=="media*|backup|data", GOTO="exit"
      ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", \
          RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --automount=yes --collect --options=uid=1000,gid=100,user,umask=000 $devnode /media/'%E{ID_FS_LABEL}'"
      ACTION=="remove", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", \
          RUN{program}+="${pkgs.systemd}/bin/systemd-mount --umount --collect /media/'%E{ID_FS_LABEL}'", \
          RUN{program}+="${pkgs.coreutils-full}/bin/rmdir /media/'%E{ID_FS_LABEL}'"
      LABEL="exit"
    '';

    # journald.extraConfig = ''
    #   RateLimitIntervalSec=30s
    #   RateLimitBurst=10000
    # '';

    # k3s = {
    #   enable = true;
    #   extraFlags = "--write-kubeconfig-mode=644 --disable-cloud-controller --disable-helm-controller --disable metrics-server --disable servicelb --disable traefik --disable helm"
    # }
  };

  # services.smartd = {
  #   enable = true;
  #   notifications.mail.enable = true;
  #   # notifications.test = true;
  #   # notifications.mail.recipient = "mysecretmail@gmail.com";
  #   notifications.wall.enable = false;
  #   devices = [
  #     {
  #       device = "DEVICESCAN";
  #       options = toString [
  #         "-a"
  #         "-o on"
  #         "-S on"
  #         "-n standby,q"
  #         "-W 4,43,50"
  #         "-m mysecretmail@gmail.com"
  #         "-M test"
  #         "-s (O/../.././09|S/../.././04|L/../../6/05)"
  #       ];
  #     }
  #   ];
  # };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
      liveRestore = false;  # https://github.com/NixOS/nixpkgs/issues/182916
    };
    # podman = {
    #   enable = true;
    #   dockerSocket.enable = true;
    # };
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
      cp = "${pkgs.xcp}/bin/xcp";
      top = "${pkgs.bottom}/bin/btm";
      nano = "${pkgs.nano}/bin/nano -E -w -i";
      nn = "${pkgs.nano}/bin/nano -E -w -i";
      # sudo = "doas";
    };
    # Moved to unstable-pkgs.nix.
    # Dont use loginShellInit. bind: command not found
    # interactiveShellInit = ''
    #   # hiSHtory: https://github.com/ddworken/hishtory
    #   source <(${pkgs.hishtory}/bin/hishtory completion bash)
    #   source ${pkgs.hishtory}/share/hishtory/config.sh
    #   # source $(nix --extra-experimental-features "nix-command flakes" eval -f '<nixpkgs>' --raw 'hishtory')/share/hishtory/config.sh
    # '';
    systemPackages = with pkgs; [
      # myPkg-linux-firmware
      # unstable-tailscale
      hishtory
      duf
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
    # fsPackages = [pkgs.mergerfs];
    # autoUpgrade.enable = true;
    # autoUpgrade.allowReboot = false;
    # autoUpgrade.channel = "https://nixos.org/channels/nixos-unstable";
    # stateVersion = "unstable";
    # autoUpgrade.channel = "https://nixos.org/channels/nixos-23.11";
    stateVersion = "23.11";
  };
}