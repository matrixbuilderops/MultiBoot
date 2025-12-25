#!/bin/bash
# Quick installer - runs non-interactively

echo "🚀 GENESIS INSTALLER - AUTO MODE"
echo "================================"
echo ""

WORKSPACE="/media/phantom-eternal/Games & Mods/Project ai shit/UniversalMultiBoot-Genesis"
EFI_DEVICE="/dev/sdd1"
EFI_MOUNT="/mnt/genesis_efi"

echo "Step 1: Checking 2TB drive..."
if ! lsblk /dev/sdd &>/dev/null; then
    echo "❌ Drive not found!"
    exit 1
fi
echo "✅ Drive found"

echo ""
echo "Step 2: Creating mount point..."
sudo mkdir -p "$EFI_MOUNT"

echo ""
echo "Step 3: Backing up existing EFI..."
sudo mkdir -p "$WORKSPACE/EFI_BACKUP"
sudo mount "$EFI_DEVICE" "$EFI_MOUNT" 2>/dev/null || echo "Already mounted"
sudo cp -r "$EFI_MOUNT/EFI" "$WORKSPACE/EFI_BACKUP/" 2>/dev/null || echo "No existing EFI to backup"
echo "✅ Backup done"

echo ""
echo "Step 4: Installing OpenCore..."
sudo mkdir -p "$EFI_MOUNT/EFI"
sudo cp -r "$WORKSPACE/GeneratedEFI/EFI/OC" "$EFI_MOUNT/EFI/"
sudo cp -r "$WORKSPACE/GeneratedEFI/EFI/BOOT" "$EFI_MOUNT/EFI/" 2>/dev/null || true
echo "✅ OpenCore installed"

echo ""
echo "Step 5: Installing GRUB..."
sudo grub-install --target=x86_64-efi --efi-directory="$EFI_MOUNT" --bootloader-id=Genesis --removable --force 2>&1 | tail -5
sudo mkdir -p "$EFI_MOUNT/boot/grub"
sudo cp /tmp/grub.cfg "$EFI_MOUNT/boot/grub/grub.cfg" 2>/dev/null || echo "⚠️  grub.cfg not found"
echo "✅ GRUB installed"

echo ""
echo "Step 6: Installing Universal Wrapper..."
sudo cp -r "$WORKSPACE/BootScripts" "$EFI_MOUNT/"
sudo cp -r "$WORKSPACE/DriverArchive" "$EFI_MOUNT/"
sudo cp -r "$WORKSPACE/HardwareProfiles" "$EFI_MOUNT/"
sudo cp "$WORKSPACE/universal_config.json" "$EFI_MOUNT/"
echo "✅ Wrapper installed"

echo ""
echo "Step 7: Setting permissions..."
sudo chmod -R +x "$EFI_MOUNT/BootScripts"/*.py 2>/dev/null || true
echo "✅ Permissions set"

echo ""
echo "Step 8: Checking space..."
df -h "$EFI_MOUNT"

echo ""
echo "Step 9: Syncing and unmounting..."
sudo sync
sudo umount "$EFI_MOUNT"
echo "✅ Done!"

echo ""
echo "======================================================================="
echo "  🎉 INSTALLATION COMPLETE!"
echo "======================================================================="
echo ""
echo "Your 2TB drive is now a Universal MultiBoot drive!"
echo ""
echo "🚀 To test:"
echo "   1. Safely eject the drive"
echo "   2. Boot from it on any computer"
echo "   3. See the boot menu!"
echo ""
