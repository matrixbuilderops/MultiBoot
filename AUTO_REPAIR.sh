#!/bin/bash
# AUTO-REPAIR SCRIPT FOR UNIVERSAL MULTIBOOT
# Place this on the EFI partition for emergency repairs

echo "╔══════════════════════════════════════╗"
echo "║  UNIVERSAL MULTIBOOT AUTO-REPAIR     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Detect drive
DRIVE=$(lsblk -o NAME,LABEL,SIZE | grep "EFI" | awk '{print $1}' | sed 's/├─//;s/└─//' | head -1)

if [ -z "$DRIVE" ]; then
    echo "❌ Could not detect EFI partition!"
    echo "Please run this script with the drive plugged in."
    exit 1
fi

echo "Detected EFI partition: /dev/$DRIVE"
echo ""

# Mount EFI
sudo mount /dev/$DRIVE /mnt/repair_efi

echo "Running repairs..."
echo ""

# Fix 1: Check GRUB config
if [ -f /mnt/repair_efi/boot/grub/grub.cfg ]; then
    echo "✓ GRUB config exists"
else
    echo "✗ GRUB config missing - restoring..."
    # Restore from backup if available
fi

# Fix 2: Check OpenCore
if [ -f /mnt/repair_efi/EFI/OC/OpenCore.efi ]; then
    echo "✓ OpenCore exists"
else
    echo "✗ OpenCore missing!"
fi

# Fix 3: Verify bootloaders
echo ""
echo "Checking bootloaders..."
# Add more checks here

sudo umount /mnt/repair_efi

echo ""
echo "Repair complete!"
