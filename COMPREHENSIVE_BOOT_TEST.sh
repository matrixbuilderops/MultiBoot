#!/bin/bash

# Comprehensive Boot System Test Suite
# Tests all modes: Windows UEFI/BIOS, Mac M1/Intel, Ubuntu on all platforms

echo "=================================="
echo "MULTIBOOT COMPREHENSIVE TEST SUITE"
echo "=================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAIL++))
    fi
}

test_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

echo "=== PHASE 1: DRIVE STRUCTURE VALIDATION ==="
echo ""

# Test 1: Drive exists and is correct size
if lsblk | grep -q "sdd.*1.8T"; then
    test_result 0 "2TB MultiBoot drive detected (sdd)"
    DRIVE="/dev/sdd"
else
    test_result 1 "2TB MultiBoot drive NOT found"
    exit 1
fi

# Test 2: Partition structure
echo ""
echo "Checking partition structure..."
sdd1_exists=$(lsblk | grep -c "sdd1")
sdd2_exists=$(lsblk | grep -c "sdd2")
sdd3_exists=$(lsblk | grep -c "sdd3")
sdd4_exists=$(lsblk | grep -c "sdd4")
sdd5_exists=$(lsblk | grep -c "sdd5")

[ $sdd1_exists -gt 0 ] && test_result 0 "Partition sdd1 (EFI) exists" || test_result 1 "Partition sdd1 missing"
[ $sdd2_exists -gt 0 ] && test_result 0 "Partition sdd2 (Windows) exists" || test_result 1 "Partition sdd2 missing"
[ $sdd3_exists -gt 0 ] && test_result 0 "Partition sdd3 (macOS) exists" || test_result 1 "Partition sdd3 missing"
[ $sdd4_exists -gt 0 ] && test_result 0 "Partition sdd4 (Ubuntu) exists" || test_result 1 "Partition sdd4 missing"
[ $sdd5_exists -gt 0 ] && test_result 0 "Partition sdd5 (UniversalBoot) exists" || test_result 1 "Partition sdd5 missing"

echo ""
echo "=== PHASE 2: BOOT FILES VALIDATION ==="
echo ""

# Test EFI partition mount and structure
mkdir -p /tmp/multiboot_test_efi
if sudo mount /dev/sdd1 /tmp/multiboot_test_efi 2>/dev/null; then
    test_result 0 "EFI partition mounted successfully"
    
    # Check EFI structure
    [ -d /tmp/multiboot_test_efi/EFI ] && test_result 0 "EFI directory exists" || test_result 1 "EFI directory missing"
    [ -d /tmp/multiboot_test_efi/EFI/BOOT ] && test_result 0 "EFI/BOOT directory exists" || test_result 1 "EFI/BOOT directory missing"
    
    sudo umount /tmp/multiboot_test_efi
else
    test_result 1 "Failed to mount EFI partition"
fi

# Test UniversalBoot partition
mkdir -p /tmp/multiboot_test_universal
if sudo mount /dev/sdd5 /tmp/multiboot_test_universal 2>/dev/null; then
    test_result 0 "UniversalBoot partition mounted successfully"
    
    # Check critical files
    [ -f /tmp/multiboot_test_universal/universal_boot_loader.sh ] && test_result 0 "universal_boot_loader.sh exists" || test_result 1 "universal_boot_loader.sh missing"
    [ -f /tmp/multiboot_test_universal/hardware_detector.sh ] && test_result 0 "hardware_detector.sh exists" || test_result 1 "hardware_detector.sh missing"
    [ -f /tmp/multiboot_test_universal/driver_injector.sh ] && test_result 0 "driver_injector.sh exists" || test_result 1 "driver_injector.sh missing"
    
    # Check archive directories
    [ -d /tmp/multiboot_test_universal/DriverArchive ] && test_result 0 "DriverArchive directory exists" || test_result 1 "DriverArchive missing"
    [ -d /tmp/multiboot_test_universal/DriverArchive/kexts ] && test_result 0 "Kexts directory exists" || test_result 1 "Kexts directory missing"
    [ -d /tmp/multiboot_test_universal/DriverArchive/linux_drivers ] && test_result 0 "Linux drivers directory exists" || test_result 1 "Linux drivers directory missing"
    [ -d /tmp/multiboot_test_universal/DriverArchive/windows_drivers ] && test_result 0 "Windows drivers directory exists" || test_result 1 "Windows drivers directory missing"
    
    sudo umount /tmp/multiboot_test_universal
else
    test_result 1 "Failed to mount UniversalBoot partition"
fi

echo ""
echo "=== PHASE 3: DRIVER ARCHIVE VALIDATION ==="
echo ""

# Mount and check driver counts
sudo mount /dev/sdd5 /tmp/multiboot_test_universal 2>/dev/null

# Count kexts
KEXT_COUNT=$(find /tmp/multiboot_test_universal/DriverArchive/kexts -name "*.kext" 2>/dev/null | wc -l)
echo "Kexts found: $KEXT_COUNT"
[ $KEXT_COUNT -gt 50 ] && test_result 0 "Sufficient kexts (${KEXT_COUNT})" || test_warning "Low kext count (${KEXT_COUNT}), recommended >50"

# Count Linux drivers
LINUX_DRIVER_COUNT=$(find /tmp/multiboot_test_universal/DriverArchive/linux_drivers -type f 2>/dev/null | wc -l)
echo "Linux drivers found: $LINUX_DRIVER_COUNT"
[ $LINUX_DRIVER_COUNT -gt 100 ] && test_result 0 "Sufficient Linux drivers (${LINUX_DRIVER_COUNT})" || test_warning "Low Linux driver count (${LINUX_DRIVER_COUNT}), recommended >100"

# Count Windows drivers
WINDOWS_DRIVER_COUNT=$(find /tmp/multiboot_test_universal/DriverArchive/windows_drivers -type f 2>/dev/null | wc -l)
echo "Windows drivers found: $WINDOWS_DRIVER_COUNT"
[ $WINDOWS_DRIVER_COUNT -gt 50 ] && test_result 0 "Sufficient Windows drivers (${WINDOWS_DRIVER_COUNT})" || test_warning "Low Windows driver count (${WINDOWS_DRIVER_COUNT}), recommended >50"

# Check for M1-specific files
M1_FILES=$(find /tmp/multiboot_test_universal -name "*asahi*" -o -name "*m1*" -o -name "*arm*" 2>/dev/null | wc -l)
echo "M1/ARM-specific files found: $M1_FILES"
[ $M1_FILES -gt 20 ] && test_result 0 "M1/ARM support files present (${M1_FILES})" || test_warning "Limited M1/ARM support (${M1_FILES} files)"

# Check OpenCore
OC_FILES=$(find /tmp/multiboot_test_universal -name "*OpenCore*" 2>/dev/null | wc -l)
[ $OC_FILES -gt 0 ] && test_result 0 "OpenCore files present" || test_result 1 "OpenCore files missing"

sudo umount /tmp/multiboot_test_universal 2>/dev/null

echo ""
echo "=== PHASE 4: SCRIPT SYNTAX VALIDATION ==="
echo ""

# Check all shell scripts for syntax errors
for script in /media/phantom-orchestrator/BitcoinNode/AI\ Projects/MultiBoot/*.sh; do
    if [ -f "$script" ]; then
        bash -n "$script" 2>/dev/null
        if [ $? -eq 0 ]; then
            test_result 0 "Syntax valid: $(basename "$script")"
        else
            test_result 1 "Syntax ERROR: $(basename "$script")"
        fi
    fi
done

echo ""
echo "=== PHASE 5: BOOT MODE COMPATIBILITY CHECK ==="
echo ""

# Check for UEFI boot support
sudo mount /dev/sdd1 /tmp/multiboot_test_efi 2>/dev/null
[ -f /tmp/multiboot_test_efi/EFI/BOOT/BOOTX64.EFI ] && test_result 0 "UEFI x64 boot file present" || test_result 1 "UEFI x64 boot file missing"
[ -f /tmp/multiboot_test_efi/EFI/BOOT/BOOTAA64.EFI ] && test_result 0 "UEFI ARM64 (M1) boot file present" || test_warning "UEFI ARM64 boot file missing (M1 may not boot)"

# Check for BIOS/Legacy boot support
if sudo dd if=/dev/sdd bs=512 count=1 2>/dev/null | grep -q "GRUB"; then
    test_result 0 "GRUB bootloader in MBR (BIOS support)"
else
    test_warning "No GRUB in MBR (BIOS boot may not work)"
fi

sudo umount /tmp/multiboot_test_efi 2>/dev/null

echo ""
echo "=== PHASE 6: CONFIGURATION VALIDATION ==="
echo ""

# Check OpenCore config
sudo mount /dev/sdd5 /tmp/multiboot_test_universal 2>/dev/null
if [ -f /tmp/multiboot_test_universal/OpenCore/config.plist ]; then
    test_result 0 "OpenCore config.plist exists"
    # Basic plist validation
    if grep -q "NVRAM" /tmp/multiboot_test_universal/OpenCore/config.plist; then
        test_result 0 "OpenCore config appears valid (NVRAM section found)"
    else
        test_result 1 "OpenCore config may be corrupted"
    fi
else
    test_result 1 "OpenCore config.plist missing"
fi

# Check for network tools
if [ -f /tmp/multiboot_test_universal/network_setup.sh ]; then
    test_result 0 "Network setup script exists"
else
    test_warning "Network setup script missing (internet fallback may not work)"
fi

sudo umount /tmp/multiboot_test_universal 2>/dev/null

echo ""
echo "=== PHASE 7: OS INSTALLATION VERIFICATION ==="
echo ""

# Check Windows
sudo mount /dev/sdd2 /tmp/multiboot_test_windows 2>/dev/null
if [ -d /tmp/multiboot_test_windows/Windows ]; then
    test_result 0 "Windows OS installed and detected"
elif [ -d /tmp/multiboot_test_windows/WINDOWS ]; then
    test_result 0 "Windows OS installed and detected"
else
    test_warning "Windows OS not detected (partition may be empty)"
fi
sudo umount /tmp/multiboot_test_windows 2>/dev/null
rmdir /tmp/multiboot_test_windows 2>/dev/null

# Check macOS
sudo mount /dev/sdd3 /tmp/multiboot_test_macos 2>/dev/null
if [ -d /tmp/multiboot_test_macos/System ]; then
    test_result 0 "macOS installed and detected"
else
    test_warning "macOS not detected (partition may be empty or APFS)"
fi
sudo umount /tmp/multiboot_test_macos 2>/dev/null
rmdir /tmp/multiboot_test_macos 2>/dev/null

# Check Ubuntu
sudo mount /dev/sdd4 /tmp/multiboot_test_ubuntu 2>/dev/null
if [ -d /tmp/multiboot_test_ubuntu/boot ]; then
    test_result 0 "Ubuntu OS installed and detected"
else
    test_warning "Ubuntu OS not detected (may need installation)"
fi
sudo umount /tmp/multiboot_test_ubuntu 2>/dev/null
rmdir /tmp/multiboot_test_ubuntu 2>/dev/null

echo ""
echo "==================================="
echo "TEST SUMMARY"
echo "==================================="
echo -e "${GREEN}PASSED${NC}: $PASS"
echo -e "${YELLOW}WARNINGS${NC}: $WARN"
echo -e "${RED}FAILED${NC}: $FAIL"
echo ""

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo -e "${GREEN}★★★ ALL TESTS PASSED - SYSTEM READY ★★★${NC}"
    exit 0
elif [ $FAIL -eq 0 ]; then
    echo -e "${YELLOW}⚠ TESTS PASSED WITH WARNINGS - REVIEW RECOMMENDED ⚠${NC}"
    exit 0
else
    echo -e "${RED}✗✗✗ TESTS FAILED - SYSTEM NOT READY ✗✗✗${NC}"
    exit 1
fi
