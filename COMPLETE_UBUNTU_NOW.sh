#!/bin/bash
# Complete Ubuntu Installation - Run with: sudo ./COMPLETE_UBUNTU_NOW.sh

set -e

UBUNTU_ROOT="/media/phantom-orchestrator/MultiBootUbuntu"

echo "=========================================="
echo "  COMPLETING UBUNTU INSTALLATION"
echo "=========================================="

echo "Step 1: Chrooting and installing packages..."
chroot $UBUNTU_ROOT /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive

echo "Updating package lists..."
apt update

echo "Installing kernel..."
apt install -y linux-image-generic linux-headers-generic

echo "Installing GRUB..."
apt install -y grub-efi-amd64 grub-efi-amd64-signed shim-signed

echo "Installing network..."
apt install -y network-manager

echo "Installing Python..."
apt install -y python3

echo "Installing graphics drivers..."
apt install -y xorg mesa-utils
apt install -y xserver-xorg-video-intel
apt install -y xserver-xorg-video-amdgpu  
apt install -y xserver-xorg-video-nouveau

echo "Installing SSH..."
apt install -y openssh-server

echo "✅ All packages installed!"
CHROOT

echo ""
echo "Step 2: Installing GRUB to EFI..."
chroot $UBUNTU_ROOT grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=UniversalMultiBoot --recheck

echo ""
echo "Step 3: Updating GRUB config..."
chroot $UBUNTU_ROOT update-grub

echo ""
echo "Step 4: Creating user..."
chroot $UBUNTU_ROOT useradd -m -s /bin/bash -G sudo multiboot || echo "User may already exist"
echo "multiboot:multiboot" | chroot $UBUNTU_ROOT chpasswd

echo ""
echo "Step 5: Setting up wrapper service..."
cat > $UBUNTU_ROOT/etc/systemd/system/universal-boot.service << 'SERVICE'
[Unit]
Description=Universal MultiBoot Wrapper
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /media/phantom-orchestrator/UniversalBoot/BootScripts/boot_menu.py
StandardInput=tty
StandardOutput=tty
TTYPath=/dev/tty1

[Install]
WantedBy=multi-user.target
SERVICE

chroot $UBUNTU_ROOT systemctl enable universal-boot.service

echo ""
echo "=========================================="
echo "  ✅ INSTALLATION COMPLETE!"
echo "=========================================="
echo ""
echo "Next: Unmount and reboot to test!"
echo "  sudo umount -R $UBUNTU_ROOT"
echo "  sudo reboot"

