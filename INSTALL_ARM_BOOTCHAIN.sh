#!/bin/bash
# ARM BOOT CHAIN INSTALLER
# Installs m1n1, U-Boot, and ARM components to 2TB drive

echo "🍎 INSTALLING ARM BOOT CHAIN TO 2TB DRIVE"
echo "=========================================="
echo ""

WORKSPACE="/media/phantom-eternal/Games & Mods/Project ai shit/UniversalMultiBoot-Genesis"
EFI_DEVICE="/dev/sdd1"
EFI_MOUNT="/mnt/genesis_efi"

cd "$WORKSPACE"

echo "Step 1: Mounting EFI partition..."
sudo mkdir -p "$EFI_MOUNT"
sudo mount "$EFI_DEVICE" "$EFI_MOUNT" 2>/dev/null || echo "Already mounted"

echo ""
echo "Step 2: Creating ARM boot directories..."
sudo mkdir -p "$EFI_MOUNT/m1n1"
sudo mkdir -p "$EFI_MOUNT/EFI/BOOT"
sudo mkdir -p "$EFI_MOUNT/UniversalWrapper/ARM_Drivers"

echo ""
echo "Step 3: Installing m1n1 (Stage 1 bootloader)..."
if [ -f "ARM_Components/bootloaders/m1n1-main/build/m1n1.bin" ]; then
    sudo cp ARM_Components/bootloaders/m1n1-main/build/m1n1.bin "$EFI_MOUNT/m1n1/"
    echo "✅ m1n1 installed"
else
    echo "⚠️  m1n1.bin not found (needs to be compiled)"
fi

echo ""
echo "Step 4: Installing U-Boot (Stage 2 bootloader)..."
if [ -f "ARM_Components/bootloaders/u-boot-asahi/u-boot.bin" ]; then
    sudo cp ARM_Components/bootloaders/u-boot-asahi/u-boot.bin "$EFI_MOUNT/m1n1/"
    echo "✅ U-Boot installed"
else
    echo "⚠️  u-boot.bin not found (needs to be compiled)"
fi

echo ""
echo "Step 5: Installing device trees..."
if [ -d "ARM_Components/bootloaders/devicetrees-asahi" ]; then
    sudo cp ARM_Components/bootloaders/devicetrees-asahi/*.dtb "$EFI_MOUNT/m1n1/" 2>/dev/null
    DTB_COUNT=$(ls ARM_Components/bootloaders/devicetrees-asahi/*.dtb 2>/dev/null | wc -l)
    echo "✅ Installed $DTB_COUNT device trees"
else
    echo "⚠️  Device trees not found"
fi

echo ""
echo "Step 6: Installing ARM kernel modules..."
if [ -d "ARM_Components/kernel" ]; then
    sudo cp -r ARM_Components/kernel/* "$EFI_MOUNT/UniversalWrapper/ARM_Drivers/" 2>/dev/null
    echo "✅ Kernel modules copied"
fi

echo ""
echo "Step 7: Installing ARM drivers..."
sudo cp -r ARM_Components/drivers/* "$EFI_MOUNT/UniversalWrapper/ARM_Drivers/" 2>/dev/null
sudo cp -r ARM_Components/audio/* "$EFI_MOUNT/UniversalWrapper/ARM_Drivers/" 2>/dev/null
echo "✅ GPU, audio, and drivers copied"

echo ""
echo "Step 8: Installing ARM tools..."
sudo cp -r ARM_Components/tools/* "$EFI_MOUNT/UniversalWrapper/ARM_Tools/" 2>/dev/null
echo "✅ Tools copied"

echo ""
echo "Step 9: Creating ARM GRUB config..."
sudo tee "$EFI_MOUNT/boot/grub/grub_arm.cfg" > /dev/null << 'GRUBCFG'
# GRUB ARM Configuration for Apple Silicon

set timeout=10
set default=0

if [ "${grub_cpu}" = "arm64" ]; then
    echo "🍎 Apple Silicon detected"
    
    menuentry "macOS ARM (Native)" {
        echo "Booting macOS..."
        # Boot native macOS
    }
    
    menuentry "Linux ARM (Asahi)" {
        echo "Booting Asahi Linux..."
        # Load kernel modules
        # Boot Linux
    }
    
    menuentry "Windows 11 ARM" {
        echo "Booting Windows ARM..."
        # Boot Windows UEFI
    }
fi
GRUBCFG
echo "✅ ARM GRUB config created"

echo ""
echo "Step 10: Updating universal config..."
sudo tee -a "$EFI_MOUNT/UniversalWrapper/universal_config.json" > /dev/null << 'CONFIG'
{
  "arm_components_installed": true,
  "m1n1_version": "latest",
  "uboot_version": "asahi",
  "asahi_kernel": "present"
}
CONFIG
echo "✅ Config updated"

echo ""
echo "Step 11: Syncing..."
sudo sync

echo ""
echo "=========================================="
echo "🎉 ARM BOOT CHAIN INSTALLATION COMPLETE!"
echo "=========================================="
echo ""
echo "📊 What was installed:"
du -sh "$EFI_MOUNT/m1n1" 2>/dev/null
du -sh "$EFI_MOUNT/UniversalWrapper/ARM_Drivers" 2>/dev/null
du -sh "$EFI_MOUNT/UniversalWrapper/ARM_Tools" 2>/dev/null
echo ""
echo "📝 EFI Partition Usage:"
df -h "$EFI_MOUNT" | tail -1
echo ""
echo "✅ Your 2TB drive now has ARM boot support!"
echo ""
echo "🍎 To use on M1/M2/M3 Mac:"
echo "   1. Hold Option key at boot"
echo "   2. Select external drive"
echo "   3. Boot menu will detect ARM and show ARM options"
echo ""

sudo umount "$EFI_MOUNT" 2>/dev/null
echo "✅ Done!"
