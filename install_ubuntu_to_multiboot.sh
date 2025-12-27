#!/bin/bash

# Ubuntu Installation Script for MultiBoot Drive
# Installs Ubuntu Server with X.org and full graphics stack

set -e

ISO_PATH="/home/phantom-orchestrator/Downloads/ubuntu-24.04.3-live-server-amd64.iso"
TARGET_PARTITION="/dev/sdd5"
MOUNT_POINT="/mnt/ubuntu_install"
EFI_PARTITION="/dev/sdd1"

echo "=== MultiBoot Ubuntu Installation ==="
echo "Target: $TARGET_PARTITION (MultiBootUbuntu)"
echo "ISO: $ISO_PATH"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# Format the partition
echo "Formatting $TARGET_PARTITION as ext4..."
mkfs.ext4 -F -L MultiBootUbuntu "$TARGET_PARTITION"

# Create and mount target
mkdir -p "$MOUNT_POINT"
mount "$TARGET_PARTITION" "$MOUNT_POINT"

# Mount ISO
ISO_MOUNT="/mnt/ubuntu_iso"
mkdir -p "$ISO_MOUNT"
mount -o loop "$ISO_PATH" "$ISO_MOUNT"

# Extract base system using debootstrap approach
echo "Installing base Ubuntu system..."
apt-get update
apt-get install -y debootstrap arch-install-scripts

# Install Ubuntu base
debootstrap --arch amd64 noble "$MOUNT_POINT" http://archive.ubuntu.com/ubuntu/

# Mount necessary filesystems
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /dev/pts "$MOUNT_POINT/dev/pts"
mount --bind /proc "$MOUNT_POINT/proc"
mount --bind /sys "$MOUNT_POINT/sys"

# Configure sources.list
cat > "$MOUNT_POINT/etc/apt/sources.list" << EOF
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF

# Chroot and install packages
cat > "$MOUNT_POINT/tmp/install.sh" << 'CHROOT_EOF'
#!/bin/bash
set -e

# Update package lists
apt-get update

# Install kernel and essential packages
apt-get install -y linux-image-generic linux-headers-generic
apt-get install -y grub-efi-amd64 grub-efi-amd64-signed shim-signed

# Install X.org and graphics stack
apt-get install -y xorg xserver-xorg-core xserver-xorg-video-all
apt-get install -y mesa-utils mesa-vulkan-drivers

# AMD graphics
apt-get install -y firmware-amd-graphics xserver-xorg-video-amdgpu

# Intel graphics
apt-get install -y intel-media-va-driver i965-va-driver intel-gpu-tools \
    xserver-xorg-video-intel

# NVIDIA graphics (proprietary drivers)
apt-get install -y nvidia-driver-535 nvidia-utils-535 || true

# Display managers and desktop environments (minimal)
apt-get install -y lightdm

# Networking
apt-get install -y network-manager wpasupplicant wireless-tools

# Essential utilities
apt-get install -y sudo openssh-server vim nano curl wget git

# Set hostname
echo "multiboot-ubuntu" > /etc/hostname

# Configure fstab
BOOT_UUID=$(blkid -s UUID -o value /dev/sdd5)
EFI_UUID=$(blkid -s UUID -o value /dev/sdd1)

cat > /etc/fstab << EOF
UUID=$BOOT_UUID / ext4 defaults 0 1
UUID=$EFI_UUID /boot/efi vfat defaults 0 1
EOF

# Install GRUB
mkdir -p /boot/efi
mount /dev/sdd1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
update-grub

# Set root password
echo "root:C0m@ndC3nt3r" | chpasswd

# Create user
useradd -m -G sudo -s /bin/bash phantom-orchestrator || true
echo "phantom-orchestrator:C0m@ndC3nt3r" | chpasswd

# Enable services
systemctl enable NetworkManager
systemctl enable ssh
systemctl enable lightdm

echo "Installation complete!"
CHROOT_EOF

chmod +x "$MOUNT_POINT/tmp/install.sh"
chroot "$MOUNT_POINT" /tmp/install.sh

# Cleanup
umount "$MOUNT_POINT/dev/pts" || true
umount "$MOUNT_POINT/dev" || true
umount "$MOUNT_POINT/proc" || true
umount "$MOUNT_POINT/sys" || true
umount "$MOUNT_POINT/boot/efi" || true
umount "$MOUNT_POINT"
umount "$ISO_MOUNT"

echo ""
echo "=== Ubuntu installation complete! ==="
echo "Partition: $TARGET_PARTITION"
echo "You can now boot into Ubuntu from the MultiBoot menu"
