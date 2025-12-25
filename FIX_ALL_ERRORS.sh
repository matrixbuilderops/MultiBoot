#!/bin/bash
echo "🔧 FIXING ALL BOOT ERRORS - FOR REAL THIS TIME"
echo "=============================================="
echo ""

# Mount EFI
echo "Mounting EFI..."
sudo mkdir -p /mnt/fix_efi
sudo mount /dev/sde1 /mnt/fix_efi
echo "✅ Mounted"
echo ""

# Check actual partition info
echo "🔍 GETTING REAL PARTITION INFO..."
echo ""
echo "Windows partition (/dev/sde2):"
sudo blkid /dev/sde2
echo ""
echo "macOS partition (/dev/sde3):"
sudo blkid /dev/sde3
echo ""
echo "Linux partition (/dev/sde4):"
sudo blkid /dev/sde4
echo ""

# Get Linux kernel version
echo "🐧 CHECKING LINUX KERNEL..."
sudo mkdir -p /mnt/linux_boot
sudo mount /dev/sde4 /mnt/linux_boot 2>/dev/null
if [ $? -eq 0 ]; then
    echo "Linux kernel files:"
    ls -1 /mnt/linux_boot/boot/vmlinuz-* 2>/dev/null | head -3
    echo ""
    echo "InitRD files:"
    ls -1 /mnt/linux_boot/boot/initrd.img-* 2>/dev/null | head -3
    sudo umount /mnt/linux_boot
else
    echo "⚠️ Could not mount Linux partition"
fi
echo ""

# Check disk mapping
echo "🗺️ GRUB DISK MAPPING..."
echo "In GRUB terms:"
echo "  hd0 = first disk detected"
echo "  hd1 = second disk detected"
echo "  etc..."
echo ""
echo "From Linux, the 2TB drive is: /dev/sde"
echo "In GRUB, this is likely: hd4 (5th disk)"
echo ""

# Check OpenCore
echo "🍎 CHECKING OPENCORE..."
if [ -f /mnt/fix_efi/EFI/OC/OpenCore.efi ]; then
    echo "✅ OpenCore.efi exists"
    ls -lh /mnt/fix_efi/EFI/OC/OpenCore.efi
else
    echo "❌ OpenCore.efi missing!"
fi
echo ""

# Check Windows bootloader
echo "🪟 CHECKING WINDOWS BOOTLOADER..."
sudo mkdir -p /mnt/win_boot
sudo mount /dev/sde2 /mnt/win_boot 2>/dev/null
if [ $? -eq 0 ]; then
    if [ -f /mnt/win_boot/EFI/Microsoft/Boot/bootmgfw.efi ]; then
        echo "✅ Windows bootloader exists at:"
        ls -lh /mnt/win_boot/EFI/Microsoft/Boot/bootmgfw.efi
    else
        echo "❌ Windows bootloader NOT at /EFI/Microsoft/Boot/bootmgfw.efi"
        echo "Searching for it..."
        find /mnt/win_boot -name "bootmgfw.efi" 2>/dev/null
    fi
    sudo umount /mnt/win_boot
else
    echo "⚠️ Could not mount Windows partition"
    echo "Trying different mount options..."
    sudo mount -t ntfs-3g /dev/sde2 /mnt/win_boot 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Mounted with ntfs-3g"
        ls -la /mnt/win_boot/ | head -10
        sudo umount /mnt/win_boot
    fi
fi
echo ""

# Check current grub.cfg
echo "📄 CURRENT GRUB CONFIG..."
echo "First 50 lines:"
head -50 /mnt/fix_efi/boot/grub/grub.cfg
echo ""

sudo umount /mnt/fix_efi
echo "Done checking. Results above."
