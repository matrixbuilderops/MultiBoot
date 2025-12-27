#!/bin/bash
set -e

UBUNTU_PART="/dev/sde5"
ISO="/home/phantom-orchestrator/Downloads/ubuntu-24.04.3-live-server-amd64.iso"
MOUNT="/tmp/ubuntu_root"
ISO_MOUNT="/tmp/ubuntu_iso"

echo "Installing Ubuntu Server to $UBUNTU_PART..."

mkdir -p "$MOUNT" "$ISO_MOUNT"
mount -o loop "$ISO" "$ISO_MOUNT"
mount "$UBUNTU_PART" "$MOUNT"

# Extract full server squashfs
unsquashfs -f -d "$MOUNT" "$ISO_MOUNT/casper/ubuntu-server-minimal.ubuntu-server.installer.squashfs"

# Mount for chroot
mount --bind /dev "$MOUNT/dev"
mount --bind /proc "$MOUNT/proc"
mount --bind /sys "$MOUNT/sys"
mount --bind "$ISO_MOUNT" "$MOUNT/mnt"

# Install inside chroot
chroot "$MOUNT" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y linux-image-generic grub-efi-amd64 grub-efi-amd64-bin
apt-get install -y xorg mesa-utils
apt-get install -y xserver-xorg-video-intel xserver-xorg-video-amdgpu xserver-xorg-video-nouveau
apt-get install -y network-manager openssh-server
echo "MultiBootUbuntu" > /etc/hostname
mkdir -p /boot/efi
echo "UUID=$(blkid -s UUID -o value /dev/sde5) / ext4 defaults 0 1" > /etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/sde1) /boot/efi vfat defaults 0 1" >> /etc/fstab
CHROOT

# Cleanup
umount "$MOUNT/mnt" "$MOUNT/dev" "$MOUNT/proc" "$MOUNT/sys"
umount "$MOUNT" "$ISO_MOUNT"

echo "Ubuntu Server installation complete!"
