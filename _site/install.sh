#!/usr/bin/bash
if [[ -b '/dev/sda' ]]; then
    disk='/dev/sda'
elif [[ -b '/dev/vda' ]]; then
    disk='/dev/vda'
else
    exit 1
fi

if ! read -rt 5 flag; then
    if ! command -v btrfs &> /dev/null; then
        echo 'btrfs command not found. Please install btrfs-progs.'
        exit 1
    fi
    sfdisk --delete "$disk"
    parted -sa  opt "$disk"             \
        mklabel gpt                     \
        mkpart  EFI     fat32   1M 1G   \
        mkpart  primary btrfs   1G 100% \
        set     1       esp     on      \
        set     2       root    on

    mkfs.fat -vF 32 "$disk"1
    if ! mkfs.btrfs -vfn 32k "$disk"2; then
        echo 'Failed to create btrfs filesystem on '$disk'2.'
        exit 1
    fi

    if ! mount -vo compress=zstd "$disk"2 /mnt; then
        echo 'Failed to mount '$disk'2.'
        exit 1
    fi
    echo -n ,home,log,pkg,.snapshots | xargs -I{} -d, btrfs -v subvolume create /mnt/@{}
    umount -vR /mnt
fi

mount -vo compress=zstd,subvol=@           "$disk"2 /mnt
mkdir -vp /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}
mount -v "$disk"1 /mnt/boot
mount -vo compress=zstd,subvol=@home       "$disk"2 /mnt/home
mount -vo compress=zstd,subvol=@log        "$disk"2 /mnt/var/log
mount -vo compress=zstd,subvol=@pkg        "$disk"2 /mnt/var/cache/pacman/pkg
mount -vo compress=zstd,subvol=@.snapshots "$disk"2 /mnt/.snapshots

[[ x"$flag" != "xblackdoor" ]] && archinstall \
    --config https://lihua.surge.sh/user_configuration.json \
    --creds https://lihua.surge.sh/user_credentials.json \
    --silent \
    --script guided \
    --debug \
    --skip-version-check
