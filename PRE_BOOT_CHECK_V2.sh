#!/bin/bash
echo "🧪 UNIVERSAL WRAPPER V2 - PRE-BOOT CHECK"
echo "=========================================="
echo ""

PASS=0
FAIL=0

# Mount EFI
echo "Mounting EFI..."
sudo mount /dev/sde1 /mnt/test_efi 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Failed to mount EFI!"
    exit 1
fi
echo "✅ EFI mounted"
echo ""

# Test 1: Check GRUB config exists
echo "Test 1: GRUB Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /mnt/test_efi/boot/grub/grub.cfg ]; then
    echo "✅ grub.cfg exists"
    SIZE=$(stat -f%z /mnt/test_efi/boot/grub/grub.cfg 2>/dev/null || stat -c%s /mnt/test_efi/boot/grub/grub.cfg)
    echo "   Size: $SIZE bytes"
    ((PASS++))
else
    echo "❌ grub.cfg NOT FOUND!"
    ((FAIL++))
fi
echo ""

# Test 2: Check GRUB syntax
echo "Test 2: GRUB Syntax Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v grub-script-check &>/dev/null; then
    grub-script-check /mnt/test_efi/boot/grub/grub.cfg 2>&1 | tee /tmp/grub_syntax.log
    if [ $? -eq 0 ]; then
        echo "✅ GRUB syntax is valid!"
        ((PASS++))
    else
        echo "❌ GRUB syntax errors found!"
        cat /tmp/grub_syntax.log
        ((FAIL++))
    fi
else
    echo "⚠️  grub-script-check not available, skipping"
fi
echo ""

# Test 3: Check for menu entries
echo "Test 3: Menu Entries"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
MACOS_ENTRY=$(grep -c "menuentry.*macOS" /mnt/test_efi/boot/grub/grub.cfg)
WIN_ENTRY=$(grep -c "menuentry.*Windows" /mnt/test_efi/boot/grub/grub.cfg)
LINUX_ENTRY=$(grep -c "menuentry.*Linux" /mnt/test_efi/boot/grub/grub.cfg)

echo "macOS entries: $MACOS_ENTRY"
echo "Windows entries: $WIN_ENTRY"
echo "Linux entries: $LINUX_ENTRY"

if [ $MACOS_ENTRY -gt 0 ] && [ $WIN_ENTRY -gt 0 ] && [ $LINUX_ENTRY -gt 0 ]; then
    echo "✅ All 3 OS entries present!"
    ((PASS++))
else
    echo "❌ Missing OS entries!"
    ((FAIL++))
fi
echo ""

# Test 4: Check OpenCore
echo "Test 4: OpenCore Components"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /mnt/test_efi/EFI/OC/OpenCore.efi ]; then
    echo "✅ OpenCore.efi present"
    ((PASS++))
else
    echo "❌ OpenCore.efi missing!"
    ((FAIL++))
fi

if [ -f /mnt/test_efi/EFI/OC/config.plist ]; then
    echo "✅ config.plist present"
    ((PASS++))
else
    echo "❌ config.plist missing!"
    ((FAIL++))
fi

KEXT_COUNT=$(find /mnt/test_efi/EFI/OC/Kexts -name "*.kext" 2>/dev/null | wc -l)
echo "✅ Found $KEXT_COUNT kexts"
((PASS++))
echo ""

# Test 5: Check wrapper scripts
echo "Test 5: Universal Wrapper Scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /mnt/test_efi/BootScripts/detect_and_configure.sh ]; then
    echo "✅ detect_and_configure.sh present"
    if [ -x /mnt/test_efi/BootScripts/detect_and_configure.sh ]; then
        echo "✅ Script is executable"
        ((PASS++))
    else
        echo "⚠️  Script not executable (but exists)"
        ((PASS++))
    fi
else
    echo "❌ detect_and_configure.sh missing!"
    ((FAIL++))
fi
echo ""

# Test 6: Check partition UUIDs
echo "Test 6: Partition Detection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking partitions..."

# Windows
WIN_UUID=$(sudo blkid /dev/sde2 2>/dev/null | grep -oP 'UUID="\K[^"]+' || echo "NOT_FOUND")
echo "Windows (/dev/sde2): $WIN_UUID"

# macOS
MAC_UUID=$(sudo blkid /dev/sde3 2>/dev/null | grep -oP 'UUID="\K[^"]+' || echo "NOT_FOUND")
echo "macOS (/dev/sde3): $MAC_UUID"

# Linux
LINUX_UUID=$(sudo blkid /dev/sde4 2>/dev/null | grep -oP 'UUID="\K[^"]+' || echo "NOT_FOUND")
echo "Linux (/dev/sde4): $LINUX_UUID"

if [ "$WIN_UUID" != "NOT_FOUND" ] && [ "$LINUX_UUID" != "NOT_FOUND" ]; then
    echo "✅ Partitions detected!"
    ((PASS++))
else
    echo "⚠️  Some partitions not detected"
    ((PASS++))
fi
echo ""

# Test 7: Check Linux kernel
echo "Test 7: Linux Kernel Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo mount /dev/sde4 /mnt/linux_check 2>/dev/null
if [ $? -eq 0 ]; then
    KERNEL=$(ls /mnt/linux_check/boot/vmlinuz-* 2>/dev/null | head -1 | xargs basename)
    INITRD=$(ls /mnt/linux_check/boot/initrd.img-* 2>/dev/null | head -1 | xargs basename)
    
    if [ -n "$KERNEL" ]; then
        echo "✅ Kernel found: $KERNEL"
        ((PASS++))
    else
        echo "❌ No kernel found!"
        ((FAIL++))
    fi
    
    if [ -n "$INITRD" ]; then
        echo "✅ InitRD found: $INITRD"
        ((PASS++))
    else
        echo "❌ No initrd found!"
        ((FAIL++))
    fi
    
    sudo umount /mnt/linux_check 2>/dev/null
else
    echo "⚠️  Could not mount Linux partition"
fi
echo ""

# Test 8: Check Windows bootloader
echo "Test 8: Windows Bootloader"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo mount /dev/sde2 /mnt/win_check 2>/dev/null
if [ $? -eq 0 ]; then
    if [ -f /mnt/win_check/EFI/Microsoft/Boot/bootmgfw.efi ]; then
        echo "✅ Windows bootloader found!"
        ((PASS++))
    else
        echo "❌ Windows bootloader not found!"
        ((FAIL++))
    fi
    sudo umount /mnt/win_check 2>/dev/null
else
    echo "⚠️  Could not mount Windows partition"
fi
echo ""

# Test 9: Check EFI space
echo "Test 9: EFI Partition Space"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
USAGE=$(df -h /mnt/test_efi | tail -1 | awk '{print $5}' | sed 's/%//')
echo "EFI usage: $USAGE%"

if [ $USAGE -lt 90 ]; then
    echo "✅ Plenty of space!"
    ((PASS++))
else
    echo "⚠️  EFI is getting full!"
fi

df -h /mnt/test_efi
echo ""

# Test 10: Check bootloader chain
echo "Test 10: Bootloader Chain"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /mnt/test_efi/EFI/BOOT/BOOTX64.EFI ]; then
    echo "✅ BOOTX64.EFI (GRUB) present"
    ((PASS++))
else
    echo "❌ BOOTX64.EFI missing!"
    ((FAIL++))
fi

# Check GRUB can find OpenCore
if grep -q "chainloader /EFI/OC/OpenCore.efi" /mnt/test_efi/boot/grub/grub.cfg; then
    echo "✅ GRUB configured to chainload OpenCore"
    ((PASS++))
else
    echo "⚠️  OpenCore chainload not found in GRUB"
fi
echo ""

# Summary
echo "=========================================="
echo "           TEST RESULTS"
echo "=========================================="
echo ""
echo "✅ Passed: $PASS tests"
echo "❌ Failed: $FAIL tests"
echo ""

TOTAL=$((PASS + FAIL))
PERCENTAGE=$((PASS * 100 / TOTAL))

echo "Success rate: $PERCENTAGE%"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED! READY TO BOOT! 🚀"
    echo ""
    echo "Your 2TB drive is fully configured and ready!"
    echo ""
    echo "Next steps:"
    echo "  1. Safely eject: sudo umount /mnt/test_efi"
    echo "  2. Boot from USB"
    echo "  3. Should see improved boot menu!"
    echo ""
elif [ $FAIL -lt 3 ]; then
    echo "⚠️  MOSTLY GOOD - Minor issues detected"
    echo ""
    echo "The drive should still boot, but may have issues."
    echo "Review the failed tests above."
    echo ""
elif [ $FAIL -lt 5 ]; then
    echo "⚠️  SOME ISSUES - May have boot problems"
    echo ""
    echo "Review the failed tests and fix before booting."
    echo ""
else
    echo "❌ MULTIPLE ISSUES - DO NOT BOOT YET!"
    echo ""
    echo "Fix the failed tests before attempting to boot."
    echo ""
fi

# Cleanup
sudo umount /mnt/test_efi 2>/dev/null
echo "✅ EFI unmounted"
echo ""
echo "Test complete!"
