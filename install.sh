#!/bin/bash

# Links
# https://nixos.wiki/wiki/Btrfs
# https://nixos.org/manual/nixos/stable/#sec-installation-manual-summary

help() {
echo \
"
SYNOPSIS
   $(basename "${BASH_SOURCE[0]}") [--help] [--noswap] [--swap-file] [--swap-partition]

DESCRIPTION
   Partition, format, mount and then install NixOS

OPTIONS
   --noswap                   Do not create swap
   --swap-file                Create swap file
   --swap-partition           Create swap partition
   --help                     Print this help
 
EXAMPLES
   $(basename "${BASH_SOURCE[0]}") --noswap
"
}

if [ -z "$1" ] || [ "$1" = "--help" ]
    then
        help
        exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# nix-env -iA nixos.git

# Partitioning
printf "Partitioning ...\n"
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
if [ "$1" = "--noswap" ]
    then
        parted /dev/sda -- mkpart primary 512MB 100%
fi
if [ "$1" = "--swap-partition" ]
    then
        parted /dev/sda -- mkpart primary 512MB -8GB
        parted /dev/sda -- mkpart primary linux-swap -8GB 100%
fi
parted /dev/sda -- set 1 esp on

# Formatting
printf "Formating ...\n"
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.btrfs -L nixos /dev/sda2
if [ "$1" = "--swap-partition" ]
    then
        mkswap -L swap /dev/sda3
        swapon /dev/sda3
fi
## create subvolumes
printf "Creating btrfs subvolumes ...\n"
mount -L nixos /mnt  # mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/var
if [ "$1" = "--swap-file" ]
    then
        btrfs subvolume create /mnt/swap
fi
umount /mnt

# Mounting
printf "Mounting ...\n"
## btrfs subvolumes
mount -o compress-force=zstd,subvol=root /dev/sda2 /mnt
mkdir /mnt/{home,nix,var}
if [ "$1" = "--swap-file" ]
    then
        mkdir /mnt/swap # with swapfile
        btrfs filesystem mkswapfile --size 2G --uuid clear /mnt/swap/swapfile
        swapon /mnt/swap/swapfile
fi
mount -o compress-force=zstd,noatime,subvol=home /dev/sda2 /mnt/home
mount -o compress-force=zstd,noatime,subvol=nix /dev/sda2 /mnt/nix
mount -o compress-force=zstd,noatime,subvol=var /dev/sda2 /mnt/var
## boot partition
mkdir -p /mnt/boot
mount -L boot /mnt/boot  # mount /dev/disk/by-label/boot /mnt/boot
## transcode partition for transcode to ram
### https://github.com/binhex/documentation/blob/master/docker/faq/plex.md
mkdir -p /mnt/transcodes
mount -t tmpfs -o size=4g -o mode=755 tmpfs /mnt/transcodes

# Generate nix config
nixos-generate-config --root /mnt

printf "Downloading my configuration.nix ...\n"
sudo curl -L -s https://github.com/queeup/nixos-mediacenter/raw/main/configuration.nix \
          -o /mnt/etc/nixos/configuration.nix

printf "Installing NixOS\n"
nixos-install --no-root-passwd