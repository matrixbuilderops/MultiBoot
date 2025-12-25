#!/bin/bash
echo "🔥 INSTALLING UNIVERSAL WRAPPER V2 TO /dev/sde!"
echo "================================================"
echo ""

EFI_MOUNT="/mnt/genesis_efi"

echo "Step 1: Creating mount point..."
sudo mkdir -p "$EFI_MOUNT"

echo ""
echo "Step 2: Mounting EFI (/dev/sde1)..."
sudo mount /dev/sde1 "$EFI_MOUNT"
echo "✅ Mounted!"

echo ""
echo "Step 3: Backing up old config..."
sudo cp "$EFI_MOUNT/boot/grub/grub.cfg" "$EFI_MOUNT/boot/grub/grub.cfg.backup" 2>/dev/null

echo ""
echo "Step 4: Installing NEW universal GRUB config..."
sudo cp /tmp/grub_universal.cfg "$EFI_MOUNT/boot/grub/grub.cfg"
echo "✅ New config installed!"

echo ""
echo "Step 5: Copying wrapper scripts..."
sudo mkdir -p "$EFI_MOUNT/BootScripts"
sudo cp BootScripts/detect_and_configure.sh "$EFI_MOUNT/BootScripts/"
sudo chmod +x "$EFI_MOUNT/BootScripts"/*.sh
echo "✅ Scripts installed!"

echo ""
echo "Step 6: Syncing..."
sudo sync

echo ""
echo "🎉 DONE! NEW GRUB CONFIG INSTALLED!"
echo ""
sudo df -h "$EFI_MOUNT"
echo ""
sudo umount "$EFI_MOUNT"
echo "✅ Unmounted!"
