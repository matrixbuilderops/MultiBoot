#!/bin/bash
set -e

UBUNTU_PART="/dev/sde5"
ISO="/home/phantom-orchestrator/Downloads/ubuntu-24.04.3-live-server-amd64.iso"
MOUNT="/tmp/ubuntu_install"
ISO_MOUNT="/tmp/iso_mount"

echo "Installing Ubuntu to $UBUNTU_PART..."

# Create mount points
mkdir -p "$MOUNT" "$ISO_MOUNT"

# Mount ISO
mount -o loop "$ISO" "$ISO_MOUNT"

# Mount partition
mount "$UBUNTU_PART" "$MOUNT"

# Extract squashfs
unsquashfs -f -d "$MOUNT" "$ISO_MOUNT/casper/filesystem.squashfs"

# Setup chroot
mount --bind /dev "$MOUNT/dev"
mount --bind /proc "$MOUNT/proc"
mount --bind /sys "$MOUNT/sys"

# Configure and install
chroot "$MOUNT" /bin/bash -c "
apt-get update
apt-get install -y linux-generic grub-efi-amd64
apt-get install -y xorg mesa-utils
apt-get install -y xserver-xorg-video-intel xserver-xorg-video-amdgpu
apt-get install -y network-manager
echo 'MultiBootUbuntu' > /etc/hostname
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Ubuntu
update-grub
"

# Cleanup
umount "$MOUNT/dev" "$MOUNT/proc" "$MOUNT/sys"
umount "$MOUNT"
umount "$ISO_MOUNT"

echo "Ubuntu installation complete!"
