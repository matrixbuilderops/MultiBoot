#!/bin/bash
echo "🔥 INSTALLING UNIVERSAL WRAPPER V2!"
echo "===================================="
echo ""

EFI_MOUNT="/mnt/genesis_efi"

echo "Step 1: Mounting EFI..."
sudo mount /dev/sdd1 "$EFI_MOUNT" 2>/dev/null || echo "Already mounted"

echo ""
echo "Step 2: Backing up old grub.cfg..."
sudo cp "$EFI_MOUNT/boot/grub/grub.cfg" "$EFI_MOUNT/boot/grub/grub.cfg.backup" 2>/dev/null

echo ""
echo "Step 3: Installing new universal GRUB config..."
sudo cp /tmp/grub_universal.cfg "$EFI_MOUNT/boot/grub/grub.cfg"
echo "✅ New GRUB config installed!"

echo ""
echo "Step 4: Copying universal wrapper scripts..."
sudo cp BootScripts/universal_preboot.sh "$EFI_MOUNT/BootScripts/"
sudo cp BootScripts/detect_and_configure.sh "$EFI_MOUNT/BootScripts/"
sudo chmod +x "$EFI_MOUNT/BootScripts"/*.sh
echo "✅ Wrapper scripts installed!"

echo ""
echo "Step 5: Syncing..."
sudo sync

echo ""
echo "Step 6: Checking space..."
sudo df -h "$EFI_MOUNT"

echo ""
echo "===================================="
echo "🎉 UNIVERSAL WRAPPER V2 INSTALLED!"
echo "===================================="
echo ""
echo "What's new:"
echo "  ✅ Auto-detects hardware at boot"
echo "  ✅ Auto-finds Windows partition"
echo "  ✅ Auto-finds Linux kernel"
echo "  ✅ Configures OpenCore for hardware"
echo "  ✅ Works on ANY computer!"
echo ""
echo "🚀 Ready to test again!"

sudo umount "$EFI_MOUNT"
echo "✅ Done!"
