#!/bin/bash
# MultiBoot Universal System - All platforms, all OSes

WORKSPACE="/media/phantom-orchestrator/BitcoinNode/AI Projects/MultiBoot"
BOOT_PART="/media/phantom-orchestrator/UniversalBoot"
EFI_PART="/dev/sdd1"

detect_hw() {
    if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
        if grep -q "apple" /sys/firmware/devicetree/base/compatible 2>/dev/null; then
            echo "m1"
        else
            echo "arm"
        fi
    elif [ "$(uname -m)" = "x86_64" ]; then
        if grep -qi "apple" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
            echo "intel-mac"
        elif [ -d "/sys/firmware/efi" ]; then
            echo "uefi"
        else
            echo "bios"
        fi
    fi
}

HW=$(detect_hw)
echo "=== MultiBoot Installer for $HW ==="

# Copy OpenCore/Asahi to boot partition
echo "Installing bootloaders..."
sudo cp -r "$WORKSPACE/OpenCore-Legacy-Patcher-main" "$BOOT_PART/" 2>/dev/null || true
sudo cp -r "$WORKSPACE/OpCoreEngine" "$BOOT_PART/" 2>/dev/null || true
sudo cp -r "$WORKSPACE/AsahiRepos" "$BOOT_PART/" 2>/dev/null || true

# Install GRUB
echo "Installing GRUB..."
sudo mkdir -p /tmp/efi
sudo mount $EFI_PART /tmp/efi 2>/dev/null || true

if [ "$HW" = "bios" ]; then
    sudo grub-install --target=i386-pc --boot-directory=/tmp/efi /dev/sdd
else
    sudo grub-install --target=x86_64-efi --efi-directory=/tmp/efi --bootloader-id=MultiBoot --removable
fi

# Create GRUB config
sudo bash -c 'cat > /tmp/efi/EFI/MultiBoot/grub.cfg << "GRUBEOF"
set timeout=30
menuentry "Windows 10 IoT" {
    search --label MultiBootWindows --set=root
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
menuentry "macOS" {
    search --label APPLE --set=root
    chainloader /System/Library/CoreServices/boot.efi
}
menuentry "Ubuntu Server" {
    search --label MultiBootUbuntu --set=root
    linux /boot/vmlinuz root=LABEL=MultiBootUbuntu
    initrd /boot/initrd.img
}
GRUBEOF'

sudo umount /tmp/efi 2>/dev/null || true
echo "=== Done! Reboot to test ===" 
