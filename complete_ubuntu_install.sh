#!/bin/bash
# Complete Ubuntu Installation and Configuration

set -e

UBUNTU_ROOT="/mnt/ubuntu_new"
EFI_PART="/dev/sdc1"
BOOT_PART="/dev/sdc4"

echo "=========================================="
echo "  COMPLETING UBUNTU INSTALLATION"
echo "=========================================="

# Install packages in chroot
echo "=== Installing essential packages ==="
chroot $UBUNTU_ROOT apt update
chroot $UBUNTU_ROOT apt install -y \
    linux-image-generic \
    linux-headers-generic \
    grub-efi-amd64 \
    grub-efi-amd64-signed \
    shim-signed \
    network-manager \
    python3 \
    xorg \
    mesa-utils \
    xserver-xorg-video-intel \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-nouveau \
    openssh-server

# Install GRUB
echo "=== Installing GRUB ==="
mount $EFI_PART $UBUNTU_ROOT/boot/efi
chroot $UBUNTU_ROOT grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=UniversalMultiBoot
chroot $UBUNTU_ROOT update-grub

# Create user
echo "=== Creating user ==="
chroot $UBUNTU_ROOT useradd -m -s /bin/bash -G sudo multiboot
echo "multiboot:multiboot" | chroot $UBUNTU_ROOT chpasswd

# Setup wrapper service
echo "=== Setting up boot wrapper ==="
cat > $UBUNTU_ROOT/etc/systemd/system/universal-boot.service << 'SERVICE'
[Unit]
Description=Universal MultiBoot Wrapper
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /mnt/universalboot/BootScripts/boot_menu.py
StandardInput=tty
StandardOutput=tty

[Install]
WantedBy=multi-user.target
SERVICE

chroot $UBUNTU_ROOT systemctl enable universal-boot.service

echo "=========================================="
echo "  ✅ INSTALLATION COMPLETE!"
echo "=========================================="
echo ""
echo "Unmount and reboot to test"

