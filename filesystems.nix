{
  fileSystems = {
    "/".options = [ "compress-force=zstd" "noatime" ];
    "/home".options = [ "compress-force=zstd" "noatime" ];
    "/nix".options = [ "compress-force=zstd" "noatime" ];
    "/var".options = [ "compress-force=zstd" "noatime" ];
    # "/swap".options = [ "noatime" ];
    "/data/media" = {
      device = "/dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1";
      fsType = "btrfs";
      options = [ "subvol=media" "compress-force=zstd" "noatime" ];
    };
    "/data/backup" = {
      device = "/dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1";
      fsType = "btrfs";
      options = [ "subvol=backup" "compress-force=zstd" "noatime" ];
    };
    "/data/photos" = {
      device = "/dev/disk/by-uuid/8b4e6bca-be8c-4314-b6ff-ce7cf59978a1";
      fsType = "btrfs";
      options = [ "subvol=photos" "compress-force=zstd" "noatime" ];
    };
    # "/transcodes" = {
    #   device = "tmpfs";
    #   fsType = "tmpfs";
    #   options = [ "size=4g" "nosuid" "nodev" "relatime" ];
    # };
    # "/mnt/media1" = {
    #   device = "/dev/disk/by-uuid/48d6c46b-a788-4c70-8bd3-fc6bfdc12eee";
    #   fsType = "btrfs";
    #   options = [ "compress-force=zstd" "noatime" "nofail" ];
    # };
    # "/mnt/media2" = {
    #   device = "/dev/disk/by-uuid/111ab0fc-2e3b-4ccc-875f-54f6c49e6d45";
    #   fsType = "btrfs";
    #   options = [ "compress-force=zstd" "noatime" "nofail" ];
    # };
    # "/data/media" = {
    #   device = "/mnt/media1:/mnt/media2";
    #   fsType = "fuse.mergerfs";
    #   options = [ "cache.files=off" "dropcacheonclose=true" "category.create=epmfs" "fsname=mergerFS"
    #               "x-systemd.after=mnt-media1.mount" "x-systemd.after=mnt-media2.mount" ];
    # };
    # "/mnt/backup" = {
    #   device = "/dev/disk/by-uuid/496a1694-0ae8-4b29-a8b3-df81eac848b5";
    #   fsType = "btrfs";
    #   options = [ "compress-force=zstd" "noatime" "nofail" ];
    # };
    # "/mnt/backup/container-data" = {
    #   device = "/dev/disk/by-uuid/496a1694-0ae8-4b29-a8b3-df81eac848b5";
    #   fsType = "btrfs";
    #   options = [ "subvol=container-data" "compress-force=zstd" "noatime" "nofail" ];
    # };
    # "/mnt/backup/immich-data" = {
    #   device = "/dev/disk/by-uuid/496a1694-0ae8-4b29-a8b3-df81eac848b5";
    #   fsType = "btrfs";
    #   options = [ "subvol=immich-data" "compress-force=zstd" "noatime" "nofail" ];
    # };
  };
}