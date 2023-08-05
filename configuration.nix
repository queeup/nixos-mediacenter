{ config, pkgs, ... }: {
  imports = [
    # "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/common/gpu/intel"
    ./hardware-configuration.nix
  ];

  boot = {
    kernelParams = [ "i915.enable_guc=2" ];  # for intel-media-driver
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

  fileSystems = {
    "/".options = [ "compress-force=zstd" ];
    "/home".options = [ "compress-force=zstd" ];
    "/nix".options = [ "compress-force=zstd" "noatime" ];
    "/var".options = [ "compress-force=zstd" "noatime" ];
    "/transcodes".options = [ "size=3g" "nosuid" "nodev" "relatime" ];
    # "/swap".options = [ "noatime" ];
    # "/mnt/media1" = {
    #   device = "/dev/disk/by-uuid/d18d0a0b-77a8-4048-a84a-58fa1b2c7572";
    #   fsType = "btrfs";
    #   options = [ "compress-force=zstd" "noatime" ];
    # };
    # "/mnt/media2" = {
    #   device = "/dev/disk/by-uuid/d1681020-8043-4f57-8f98-e5c028ae0a4f";
    #   fsType = "btrfs";
    #   options = [ "compress-force=zstd" "noatime" ];
    # };

    # "/data" = {
    #   device = "/mnt/media1:/mnt/media2";
    #   fsType = "fuse.mergerfs";
    #   options = ["allow_other" "use_ino" "cache.files=partial" "dropcacheonclose=true" "category.create=mfs"];
    # };
  };

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
    hostName = "nixos";
    firewall.enable = false;
  };

  time.timeZone = "Europe/Istanbul";

  console = {
    keyMap = "trq";
  };
  
  users = {
    mutableUsers = false;
    users.user = {
      isNormalUser = true;
      initialHashedPassword = "$y$j9T$t/JLlePX4G9z5V4xdJXCV1$7kWMxU3Sc0IOpvoTqXzk2U2es2hdMDLUGytnvTgx282";  # printf password | mkpasswd -s
      home = "/home/user";
      extraGroups = [
        "wheel"
        "docker"
        #"podman"
        #"render"
        #"video"
        #"networkmanager"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5ZoG0AtQlWgFJaIYnRznbgxQ/NQEvQunUzHcXgAT/p nixos"  # ssh-keygen -t ed25519 -f </folder/keyfile> -C <comment>
      ];
      # packages = with pkgs; [
      #   tree
      # ];
    };
  };

  security = {
    # doas.enable = true;
    # doas.wheelNeedsPassword = false;
    # sudo.enable = false;
    sudo.wheelNeedsPassword = false;
  };

  services = {
    fstrim.enable = true;
    # fwupd.enable = true;
    sshd.enable = true;
    openssh = {
      settings.PasswordAuthentication = false;
      settings.PermitRootLogin = "no";
    };
    tailscale = {
      enable = true;
      # extraUpFlags = [ "--ssh" ];
    };
    # hints from https://dataswamp.org/~solene/2021-12-21-my-nixos.html
    cron.systemCronJobs = [
      "0 20 * * * root journalctl --vacuum-time=2d"  # clean logs older than 2d
      "0 1 * * * root rtcwake -m mem --date +6h"  # auto standby
    ];
    # Automount USB disks.
    # hints from: https://wiki.archlinux.org/title/Udev#Mounting_drives_in_rules
    #             https://unix.stackexchange.com/a/657698
    #             man --pager="less -p ^EXAMPLE" systemd-mount
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", \
          RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --automount=yes --collect --options=uid=1000,gid=100,user,umask=000 $devnode /media/'%E{ID_FS_LABEL}'"
      ACTION=="remove", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", \
          RUN{program}+="${pkgs.systemd}/bin/systemd-mount --umount --collect /media/'%E{ID_FS_LABEL}'", \
          RUN{program}+="${pkgs.coreutils-full}/bin/rmdir /media/'%E{ID_FS_LABEL}'"
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

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
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
      ls = "${pkgs.exa}/bin/exa --group-directories-first";
      ll = "${pkgs.exa}/bin/exa --all --long --group-directories-first --octal-permissions";
      cp = "${pkgs.xcp}/bin/xcp";
      top = "${pkgs.bottom}/bin/btm";
      nano = "${pkgs.nano}/bin/nano -E -w -i";
      nn = "${pkgs.nano}/bin/nano -E -w -i";
      # sudo = "doas";
    };
    # Dont use loginShellInit. bind: command not found
    interactiveShellInit = ''
      # hiSHtory: https://github.com/ddworken/hishtory
      source <(${pkgs.hishtory}/bin/hishtory completion bash)
      source ${pkgs.hishtory}/share/hishtory/config.sh
      # source $(nix --extra-experimental-features "nix-command flakes" eval -f '<nixpkgs>' --raw 'hishtory')/share/hishtory/config.sh
    '';
    systemPackages = with pkgs; [
      linux-firmware
      hishtory
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
    fsPackages = [pkgs.mergerfs];
    autoUpgrade.enable = true;
    autoUpgrade.allowReboot = false;
    autoUpgrade.channel = "https://channels.nixos.org/nixos-unstable";
    stateVersion = "unstable";
  };
}