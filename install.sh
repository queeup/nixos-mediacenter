#!/usr/bin/env bash

# Links
# https://nixos.wiki/wiki/Btrfs
# https://nixos.org/manual/nixos/stable/#sec-installation-manual-summary

DEVICE=""
CREATE_SWAP=0
CPU=""

function help() {
echo \
"
SYNOPSIS
   $(basename "${BASH_SOURCE[0]}") [--help]

DESCRIPTION
   Partition, format, mount and then install NixOS

OPTIONS
   --device                   Device to install
   --cpu [amd|intel]          Specify the CPU vendor (amd or intel)
   --swap-file                Create swap file
   --help                     Print this help
"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --device)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --device requires a device path (e.g., /dev/sda)"
                exit 1
            fi
            DEVICE="$2"
            shift 2
            ;;
        --cpu)
            # CPU argümanının amd veya intel olup olmadığını kontrol et
            if [[ "$2" != "amd" && "$2" != "intel" ]]; then
                echo "Error: --cpu must be 'amd' or 'intel'"
                exit 1
            fi
            CPU="$2"
            shift 2
            ;;
        --swap-file)
            CREATE_SWAP=1
            shift 1
            ;;
        --help)
            help
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            help
            exit 1
            ;;
    esac
done

if [ -z "$DEVICE" ]; then
    echo "Please submit a device to install (e.g., --device /dev/sda)"
    help
    exit 1
fi

if [ -z "$CPU" ]; then
    echo "Please specify a CPU vendor (e.g., --cpu amd)"
    help
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Partitioning
printf "\nPartitioning %s ...\n" "${DEVICE}"
parted "${DEVICE}" -- mklabel gpt
parted "${DEVICE}" -- mkpart root btrfs 512MB 100%
parted "${DEVICE}" -- mkpart ESP fat32 1MB 512MB
parted "${DEVICE}" -- set 2 esp on
partprobe "${DEVICE}"
udevadm settle

# Formatting
printf "\nFormatting partitions on %s ...\n" "${DEVICE}"
mkfs.btrfs -L nixos "/dev/disk/by-partlabel/root"
mkfs.fat -F 32 -n boot "/dev/disk/by-partlabel/ESP"

## create subvolumes
printf "\nCreating btrfs subvolumes ...\n"
mount "/dev/disk/by-partlabel/root" /mnt  # mount -L nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@var
chattr +C /mnt/@nix  # disable CoW
chattr +C /mnt/@var  # disable CoW
if [ "$CREATE_SWAP" -eq 1 ]; then
    btrfs subvolume create /mnt/@swap
    chattr +C /mnt/@swap  # disable CoW
fi
umount /mnt

# Mounting
printf "\nMounting partitions ...\n"
## btrfs subvolumes
mount -o compress=zstd,subvol=@ "/dev/disk/by-partlabel/root" /mnt
mkdir -p /mnt/{home,nix,var}
mount -o compress=zstd,noatime,subvol=@home "/dev/disk/by-partlabel/root" /mnt/home
mount -o noatime,subvol=@nix "/dev/disk/by-partlabel/root" /mnt/nix  # nodatacow with chattr +C /mnt/@nix
mount -o noatime,subvol=@var "/dev/disk/by-partlabel/root" /mnt/var  # nodatacow with chattr +C /mnt/@var
if [ "$CREATE_SWAP" -eq 1 ]; then
    mkdir -p /mnt/swap
    mount -o noatime,subvol=@swap "/dev/disk/by-partlabel/root" /mnt/swap  # nodatacow with chattr +C /mnt/@swap
    btrfs filesystem mkswapfile --size 4G --uuid clear /mnt/swap/swapfile
    swapon /mnt/swap/swapfile
fi

## boot partition
mkdir -p /mnt/boot
mount -o umask=0077 "/dev/disk/by-partlabel/ESP" /mnt/boot  # mount -o umask=0077 -L boot /mnt/boot

# Generate nix config
# nixos-generate-config --root /mnt

printf "\nDownloading and generating configuration files ...\n"
curl --silent --create-dirs --remote-name --location --output-dir /mnt/etc/nixos \
    "https://github.com/queeup/nixos-mediacenter/raw/main/{configuration-${CPU},filesystems,restic-backups,systemd-services,unstable-pkgs,users}.nix"
nixos-generate-config --root /mnt --show-hardware-config > /mnt/etc/nixos/hardware-configuration.nix

printf "\nSetting up %s configuration ...\n" "${CPU}"
ln -srf "/mnt/etc/nixos/configuration-${CPU}.nix" "/mnt/etc/nixos/configuration.nix"

printf "\nInstalling NixOS\n"
nixos-install --no-root-passwd
