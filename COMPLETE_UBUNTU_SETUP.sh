#!/bin/bash

# Complete Ubuntu Installation and Configuration Script
DEVICE="/dev/sde"
UBUNTU_PART="${DEVICE}3"
MULTIBOOT_PART="${DEVICE}4"
MOUNT_POINT="/mnt/multiboot_ubuntu"
ISO_PATH="/home/phantom-orchestrator/Downloads/ubuntu-24.04.1-live-server-amd64.iso"
ISO_MOUNT="/mnt/ubuntu_iso"

echo "=== COMPLETE UBUNTU INSTALLATION ==="

# Verify drive is connected
if [ ! -b "$DEVICE" ]; then
    echo "ERROR: Drive $DEVICE not found!"
    exit 1
fi

# Create mount points
sudo mkdir -p "$MOUNT_POINT" "$ISO_MOUNT"

# Mount ISO
echo "Mounting ISO..."
sudo mount -o loop "$ISO_PATH" "$ISO_MOUNT"

# Mount Ubuntu partition
echo "Mounting Ubuntu partition..."
sudo mount "$UBUNTU_PART" "$MOUNT_POINT"

# Extract filesystem squashfs
echo "Extracting Ubuntu filesystem..."
sudo unsquashfs -f -d "$MOUNT_POINT" "$ISO_MOUNT/casper/filesystem.squashfs"

# Setup chroot environment
echo "Setting up chroot environment..."
sudo mount --bind /dev "$MOUNT_POINT/dev"
sudo mount --bind /dev/pts "$MOUNT_POINT/dev/pts"
sudo mount --bind /proc "$MOUNT_POINT/proc"
sudo mount --bind /sys "$MOUNT_POINT/sys"

# Create installation script to run in chroot
cat << 'CHROOT_EOF' | sudo tee "$MOUNT_POINT/tmp/setup.sh" > /dev/null
#!/bin/bash

# Update package lists
apt-get update

# Install kernel and bootloader
apt-get install -y linux-image-generic linux-headers-generic grub-efi-amd64

# Install Xorg and graphics drivers
apt-get install -y xorg mesa-utils
apt-get install -y xserver-xorg-video-intel xserver-xorg-video-amdgpu xserver-xorg-video-nouveau
apt-get install -y firmware-linux firmware-linux-nonfree intel-microcode amd64-microcode

# Install additional utilities
apt-get install -y network-manager openssh-server

# Setup fstab
UUID=$(blkid -s UUID -o value /dev/sdb3)
cat > /etc/fstab << EOF
UUID=$UUID / ext4 errors=remount-ro 0 1
UUID=$(blkid -s UUID -o value /dev/sdb1) /boot/efi vfat umask=0077 0 1
