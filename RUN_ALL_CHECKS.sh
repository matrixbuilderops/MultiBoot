#!/bin/bash
echo "🔍 RUNNING COMPREHENSIVE PRE-BOOT CHECKS"
echo "=========================================="
echo ""

# CHECK 1: Linux Partition
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CHECK 1: LINUX PARTITION (/dev/sde4)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Partition info:"
sudo blkid /dev/sde4
echo ""

echo "Attempting to mount..."
sudo mkdir -p /mnt/linux_check
sudo umount /mnt/linux_check 2>/dev/null

if sudo mount /dev/sde4 /mnt/linux_check 2>/dev/null; then
    echo "✅ Linux partition mounted successfully!"
    echo ""
    echo "Checking for kernel files..."
    
    # Check for symlinks
    if [ -L /mnt/linux_check/boot/vmlinuz ]; then
        echo "✅ /boot/vmlinuz symlink exists"
        KERNEL_TARGET=$(readlink -f /mnt/linux_check/boot/vmlinuz)
        echo "   Points to: $KERNEL_TARGET"
    else
        echo "❌ /boot/vmlinuz symlink NOT found"
        echo "   Available kernels:"
        ls -1 /mnt/linux_check/boot/vmlinuz-* 2>/dev/null | head -5
    fi
    
    if [ -L /mnt/linux_check/boot/initrd.img ]; then
        echo "✅ /boot/initrd.img symlink exists"
        INITRD_TARGET=$(readlink -f /mnt/linux_check/boot/initrd.img)
        echo "   Points to: $INITRD_TARGET"
    else
        echo "❌ /boot/initrd.img symlink NOT found"
        echo "   Available initrds:"
        ls -1 /mnt/linux_check/boot/initrd.img-* 2>/dev/null | head -5
    fi
    
    echo ""
    echo "All boot files:"
    ls -lh /mnt/linux_check/boot/ | grep -E "vmlinuz|initrd" | head -10
    
    sudo umount /mnt/linux_check
else
    echo "❌ FAILED to mount Linux partition!"
    echo ""
    echo "Checking if encrypted (LUKS)..."
    sudo cryptsetup isLuks /dev/sde4
    if [ $? -eq 0 ]; then
        echo "⚠️  Partition IS encrypted with LUKS!"
        echo "   Need to decrypt before booting"
    else
        echo "   Not LUKS encrypted"
    fi
    
    echo ""
    echo "Checking filesystem..."
    sudo fsck -N /dev/sde4 2>&1 | grep -i "type"
    
    echo ""
    echo "Trying different mount options..."
    sudo mount -o ro /dev/sde4 /mnt/linux_check 2>&1
fi
echo ""

# CHECK 2: Windows Partition
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CHECK 2: WINDOWS PARTITION (/dev/sde2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Partition info:"
sudo blkid /dev/sde2
echo ""

echo "Attempting to mount..."
sudo mkdir -p /mnt/win_check
sudo umount /mnt/win_check 2>/dev/null

if sudo mount -t ntfs-3g /dev/sde2 /mnt/win_check 2>/dev/null; then
    echo "✅ Windows partition mounted!"
    echo ""
    
    # Check bootloader locations
    echo "Checking bootloader locations..."
    
    if [ -f /mnt/win_check/Windows/Boot/EFI/bootmgfw.efi ]; then
        echo "✅ Found: /Windows/Boot/EFI/bootmgfw.efi"
        ls -lh /mnt/win_check/Windows/Boot/EFI/bootmgfw.efi
    else
        echo "❌ NOT at /Windows/Boot/EFI/bootmgfw.efi"
    fi
    
    if [ -f /mnt/win_check/EFI/Microsoft/Boot/bootmgfw.efi ]; then
        echo "✅ Found: /EFI/Microsoft/Boot/bootmgfw.efi"
        ls -lh /mnt/win_check/EFI/Microsoft/Boot/bootmgfw.efi
    else
        echo "❌ NOT at /EFI/Microsoft/Boot/bootmgfw.efi"
    fi
    
    echo ""
    echo "Checking BCD (Boot Configuration Data)..."
    if [ -f /mnt/win_check/Boot/BCD ]; then
        echo "✅ BCD found at /Boot/BCD"
        ls -lh /mnt/win_check/Boot/BCD
    elif [ -f /mnt/win_check/Windows/Boot/BCD ]; then
        echo "✅ BCD found at /Windows/Boot/BCD"
        ls -lh /mnt/win_check/Windows/Boot/BCD
    else
        echo "⚠️  BCD not found in common locations"
    fi
    
    echo ""
    echo "Windows directory structure:"
    ls -la /mnt/win_check/ | head -15
    
    sudo umount /mnt/win_check
else
    echo "❌ FAILED to mount Windows partition!"
fi
echo ""

# CHECK 3: macOS Partition
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CHECK 3: MACOS PARTITION (/dev/sde3)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Partition info:"
sudo blkid /dev/sde3
echo ""

echo "Checking if APFS can be mounted on Linux..."
if command -v apfs-fuse &>/dev/null; then
    echo "✅ apfs-fuse is installed"
    sudo mkdir -p /mnt/macos_check
    sudo apfs-fuse /dev/sde3 /mnt/macos_check 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Mounted APFS!"
        ls -la /mnt/macos_check/ | head -10
        sudo umount /mnt/macos_check
    else
        echo "⚠️  Could not mount APFS"
    fi
else
    echo "⚠️  apfs-fuse not installed (expected)"
    echo "   Can't check macOS filesystem from Linux"
fi

echo ""
echo "APFS on external drive analysis:"
echo "  • macOS APFS on external = needs special boot config"
echo "  • OpenCore needs to be configured for external boot"
echo "  • SecureBootModel must be disabled"
echo ""

# CHECK 4: EFI Partition
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CHECK 4: EFI PARTITION (/dev/sde1)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sudo mkdir -p /mnt/efi_check
sudo mount /dev/sde1 /mnt/efi_check 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ EFI partition mounted"
    echo ""
    
    echo "Checking OpenCore configuration..."
    if [ -f /mnt/efi_check/EFI/OC/config.plist ]; then
        echo "✅ config.plist exists"
        
        # Check for external boot settings
        echo ""
        echo "Checking for external boot configurations..."
        
        if grep -q "SecureBootModel" /mnt/efi_check/EFI/OC/config.plist; then
            echo "  SecureBootModel: $(grep -A1 "SecureBootModel" /mnt/efi_check/EFI/OC/config.plist | tail -1)"
        else
            echo "  ⚠️  SecureBootModel not found"
        fi
        
        if grep -q "BlessOverride" /mnt/efi_check/EFI/OC/config.plist; then
            echo "  ✅ BlessOverride configured"
        else
            echo "  ⚠️  BlessOverride not found (needed for external boot)"
        fi
    fi
    
    echo ""
    echo "GRUB configuration:"
    if [ -f /mnt/efi_check/boot/grub/grub.cfg ]; then
        echo "✅ grub.cfg exists"
        echo "   Size: $(stat -c%s /mnt/efi_check/boot/grub/grub.cfg) bytes"
        echo ""
        echo "Menu entries found:"
        grep "menuentry" /mnt/efi_check/boot/grub/grub.cfg | head -5
    fi
    
    sudo umount /mnt/efi_check
fi
echo ""

# SUMMARY
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Results saved. Review above for issues."
echo ""
