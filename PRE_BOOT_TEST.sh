#!/bin/bash
echo "🧪 PRE-BOOT TEST CHECKLIST"
echo "=========================="
echo ""

echo "1️⃣ Checking 2TB drive..."
if lsblk /dev/sdd &>/dev/null; then
    echo "✅ 2TB drive present: /dev/sdd"
    lsblk /dev/sdd
else
    echo "❌ 2TB drive NOT found!"
    exit 1
fi

echo ""
echo "2️⃣ Mounting EFI partition..."
sudo mkdir -p /mnt/test_efi
sudo mount /dev/sdd1 /mnt/test_efi 2>/dev/null
if mount | grep -q /dev/sdd1; then
    echo "✅ EFI mounted at /mnt/test_efi"
else
    echo "❌ Failed to mount EFI"
    exit 1
fi

echo ""
echo "3️⃣ Checking OpenCore..."
if [ -f /mnt/test_efi/EFI/OC/OpenCore.efi ]; then
    echo "✅ OpenCore.efi present"
    ls -lh /mnt/test_efi/EFI/OC/OpenCore.efi
else
    echo "❌ OpenCore.efi NOT found!"
fi

echo ""
echo "4️⃣ Checking config.plist..."
if [ -f /mnt/test_efi/EFI/OC/config.plist ]; then
    echo "✅ config.plist present"
    ls -lh /mnt/test_efi/EFI/OC/config.plist
else
    echo "❌ config.plist NOT found!"
fi

echo ""
echo "5️⃣ Checking GRUB..."
if [ -f /mnt/test_efi/EFI/BOOT/BOOTX64.EFI ]; then
    echo "✅ BOOTX64.EFI present (GRUB)"
    ls -lh /mnt/test_efi/EFI/BOOT/BOOTX64.EFI
else
    echo "❌ BOOTX64.EFI NOT found!"
fi

if [ -f /mnt/test_efi/boot/grub/grub.cfg ]; then
    echo "✅ grub.cfg present"
else
    echo "❌ grub.cfg NOT found!"
fi

echo ""
echo "6️⃣ Checking kexts..."
KEXT_COUNT=$(find /mnt/test_efi/EFI/OC/Kexts -name "*.kext" 2>/dev/null | wc -l)
echo "✅ Found $KEXT_COUNT kexts"

echo ""
echo "7️⃣ Checking Universal Wrapper..."
if [ -d /mnt/test_efi/UniversalWrapper ]; then
    echo "✅ UniversalWrapper directory present"
    ls -lh /mnt/test_efi/UniversalWrapper/
else
    echo "⚠️  UniversalWrapper not found (optional)"
fi

echo ""
echo "8️⃣ Checking EFI space..."
df -h /mnt/test_efi

echo ""
echo "9️⃣ Verifying boot order..."
efibootmgr 2>/dev/null | head -10

echo ""
echo "=========================="
echo "🎯 TEST RESULTS SUMMARY:"
echo "=========================="
echo ""

# Count checks
CHECKS_PASSED=0
if lsblk /dev/sdd &>/dev/null; then ((CHECKS_PASSED++)); fi
if [ -f /mnt/test_efi/EFI/OC/OpenCore.efi ]; then ((CHECKS_PASSED++)); fi
if [ -f /mnt/test_efi/EFI/OC/config.plist ]; then ((CHECKS_PASSED++)); fi
if [ -f /mnt/test_efi/EFI/BOOT/BOOTX64.EFI ]; then ((CHECKS_PASSED++)); fi
if [ $KEXT_COUNT -gt 0 ]; then ((CHECKS_PASSED++)); fi

echo "Checks passed: $CHECKS_PASSED/5"
echo ""

if [ $CHECKS_PASSED -eq 5 ]; then
    echo "✅ ALL CHECKS PASSED!"
    echo ""
    echo "🚀 READY TO BOOT!"
    echo ""
    echo "To test:"
    echo "  1. Save all work"
    echo "  2. Run: sudo reboot"
    echo "  3. Press F12/F11/Del during boot"
    echo "  4. Select 'G-DRIVE SSD' or 'USB Boot'"
    echo "  5. You should see GRUB menu!"
    echo ""
else
    echo "⚠️  Some checks failed. Review above."
fi

sudo umount /mnt/test_efi
echo ""
echo "Done!"

