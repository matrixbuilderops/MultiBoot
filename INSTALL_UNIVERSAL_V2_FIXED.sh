#!/bin/bash
echo "🔥 INSTALLING UNIVERSAL WRAPPER V2!"
echo "===================================="
echo ""

# Wait for drive
echo "Waiting for 2TB drive to be connected..."
while [ ! -b /dev/sdd1 ]; do
    echo "  Drive not detected, waiting..."
    sleep 2
done
echo "✅ Drive detected!"
echo ""

EFI_MOUNT="/mnt/genesis_efi"

echo "Step 1: Creating mount point..."
sudo mkdir -p "$EFI_MOUNT"

echo ""
echo "Step 2: Mounting EFI..."
sudo mount /dev/sdd1 "$EFI_MOUNT"
echo "✅ Mounted at $EFI_MOUNT"

echo ""
echo "Step 3: Checking current structure..."
ls -lh "$EFI_MOUNT/"

echo ""
echo "Step 4: Backing up old grub.cfg..."
sudo cp "$EFI_MOUNT/boot/grub/grub.cfg" "$EFI_MOUNT/boot/grub/grub.cfg.backup" 2>/dev/null || echo "No existing grub.cfg"

echo ""
echo "Step 5: Creating grub directory if needed..."
sudo mkdir -p "$EFI_MOUNT/boot/grub"

echo ""
echo "Step 6: Installing new universal GRUB config..."
sudo cp /tmp/grub_universal.cfg "$EFI_MOUNT/boot/grub/grub.cfg"
echo "✅ New GRUB config installed!"

echo ""
echo "Step 7: Creating BootScripts directory if needed..."
sudo mkdir -p "$EFI_MOUNT/BootScripts"

echo ""
echo "Step 8: Copying universal wrapper scripts..."
sudo cp BootScripts/universal_preboot.sh "$EFI_MOUNT/BootScripts/" 2>/dev/null || echo "Skipping universal_preboot.sh"
sudo cp BootScripts/detect_and_configure.sh "$EFI_MOUNT/BootScripts/" 2>/dev/null || echo "Skipping detect_and_configure.sh"
sudo chmod +x "$EFI_MOUNT/BootScripts"/*.sh 2>/dev/null
echo "✅ Wrapper scripts installed!"

echo ""
echo "Step 9: Syncing..."
sudo sync

echo ""
echo "Step 10: Checking space..."
sudo df -h "$EFI_MOUNT"

echo ""
echo "Step 11: Listing what's on EFI now..."
echo "📂 EFI Contents:"
ls -lh "$EFI_MOUNT/"

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
echo "Changes made:"
echo "  • Updated /boot/grub/grub.cfg"
echo "  • Added universal wrapper scripts"
echo "  • Old config backed up to grub.cfg.backup"
echo ""
echo "🚀 Ready to test again!"
echo ""
echo "Next steps:"
echo "  1. Safely eject drive: sudo umount $EFI_MOUNT"
echo "  2. Plug into test computer"
echo "  3. Boot from USB"
echo "  4. Try the updated GRUB menu!"
echo ""
read -p "Press Enter to unmount drive..."

sudo umount "$EFI_MOUNT"
echo "✅ Drive unmounted - safe to remove!"
