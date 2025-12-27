#!/bin/bash
set -e

UBUNTU_PART="/dev/sde5"
MOUNT="/tmp/ubuntu_install"
EFI_PART="/dev/sde1"

echo "Installing Ubuntu via debootstrap..."

# Install debootstrap if needed
apt-get update && apt-get install -y debootstrap

# Mount partition  
mkdir -p "$MOUNT"
mount "$UBUNTU_PART" "$MOUNT"

# Debootstrap noble (24.04)
debootstrap --arch=amd64 noble "$MOUNT" http://archive.ubuntu.com/ubuntu/

# Mount for chroot
mount --bind /dev "$MOUNT/dev"
mount --bind /proc "$MOUNT/proc"
mount --bind /sys "$MOUNT/sys"
mount --bind /dev/pts "$MOUNT/dev/pts"

# Configure inside chroot
chroot "$MOUNT" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive

# Setup sources
cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

apt-get update
apt-get install -y linux-image-generic linux-headers-generic
apt-get install -y grub-efi-amd64 grub-efi-amd64-bin efibootmgr
apt-get install -y xorg mesa-utils
apt-get install -y xserver-xorg-video-intel xserver-xorg-video-amdgpu xserver-xorg-video-nouveau xserver-xorg-video-fbdev
apt-get install -y firmware-linux firmware-linux-nonfree intel-microcode amd64-microcode
apt-get install -y network-manager openssh-server sudo
apt-get install -y vim nano wget curl

echo "MultiBootUbuntu" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "127.0.1.1 MultiBootUbuntu" >> /etc/hosts

# Setup fstab
mkdir -p /boot/efi
UUID_ROOT=$(blkid -s UUID -o value /dev/sde5)
UUID_EFI=$(blkid -s UUID -o value /dev/sde1)
cat > /etc/fstab << EOF
UUID=$UUID_ROOT / ext4 errors=remount-ro 0 1
UUID=$UUID_EFI /boot/efi vfat umask=0077 0 1
EOF

# Install GRUB
mount /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Ubuntu --recheck
update-grub

systemctl enable NetworkManager

echo "Setup complete!"
CHROOT

# Cleanup
umount "$MOUNT/dev/pts" "$MOUNT/dev" "$MOUNT/proc" "$MOUNT/sys"
umount "$MOUNT"

echo "Ubuntu installation complete!"
