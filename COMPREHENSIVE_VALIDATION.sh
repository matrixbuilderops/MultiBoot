#!/bin/bash
# Comprehensive MultiBoot System Validation
# Tests all components for UEFI/BIOS Windows, M1/Intel Mac compatibility

echo "======================================"
echo "MULTIBOOT COMPREHENSIVE VALIDATION"
echo "======================================"
echo ""

# Colors
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

warn_result() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

echo "=== 1. DRIVE DETECTION ==="
DRIVE="/dev/sdg"
if [ -b "$DRIVE" ]; then
    test_result 0 "MultiBoot drive detected at $DRIVE"
    SIZE=$(lsblk -b -d -n -o SIZE $DRIVE 2>/dev/null)
    if [ $SIZE -gt 1800000000000 ]; then
        test_result 0 "Drive size appropriate ($(numfmt --to=iec $SIZE))"
    else
        test_result 1 "Drive size too small ($(numfmt --to=iec $SIZE))"
    fi
else
    test_result 1 "MultiBoot drive NOT detected"
fi

echo ""
echo "=== 2. PARTITION STRUCTURE ==="
for PART in sdg1 sdg2 sdg3 sdg4 sdg5; do
    if [ -b "/dev/$PART" ]; then
        SIZE=$(lsblk -b -n -o SIZE /dev/$PART 2>/dev/null)
        test_result 0 "$PART exists ($(numfmt --to=iec $SIZE))"
    else
        test_result 1 "$PART missing"
    fi
done

echo ""
echo "=== 3. EFI PARTITION CHECK ==="
MOUNT_EFI=$(mount | grep sdg1)
if [ -n "$MOUNT_EFI" ]; then
    test_result 0 "EFI partition mountable"
else
    warn_result "EFI partition not currently mounted"
fi

echo ""
echo "=== 4. UNIVERSAL BOOT PARTITION ==="
if [ -d "/media/phantom-orchestrator/UniversalBoot" ]; then
    test_result 0 "UniversalBoot partition mounted"
    
    # Check boot scripts
    SCRIPTS=("universal_boot.sh" "detect_hardware.sh" "inject_drivers.sh" "network_handler.sh")
    for SCRIPT in "${SCRIPTS[@]}"; do
        if [ -f "/media/phantom-orchestrator/UniversalBoot/boot/$SCRIPT" ]; then
            test_result 0 "Boot script: $SCRIPT"
            # Check if executable
            if [ -x "/media/phantom-orchestrator/UniversalBoot/boot/$SCRIPT" ]; then
                test_result 0 "$SCRIPT is executable"
            else
                test_result 1 "$SCRIPT not executable"
            fi
        else
            test_result 1 "Boot script missing: $SCRIPT"
        fi
    done
else
    test_result 1 "UniversalBoot partition NOT mounted"
fi

echo ""
echo "=== 5. DRIVER ARCHIVE VALIDATION ==="
ARCHIVE_PATH="/media/phantom-orchestrator/UniversalBoot/DriverArchive"
if [ -d "$ARCHIVE_PATH" ]; then
    test_result 0 "Driver archive directory exists"
    
    # Check categories
    CATEGORIES=("Windows" "Linux" "macOS" "Asahi" "Firmware")
    for CAT in "${CATEGORIES[@]}"; do
        if [ -d "$ARCHIVE_PATH/$CAT" ]; then
            COUNT=$(find "$ARCHIVE_PATH/$CAT" -type f 2>/dev/null | wc -l)
            SIZE=$(du -sh "$ARCHIVE_PATH/$CAT" 2>/dev/null | cut -f1)
            if [ $COUNT -gt 100 ]; then
                test_result 0 "$CAT drivers ($COUNT files, $SIZE)"
            elif [ $COUNT -gt 10 ]; then
                warn_result "$CAT drivers sparse ($COUNT files, $SIZE)"
            else
                test_result 1 "$CAT drivers insufficient ($COUNT files)"
            fi
        else
            test_result 1 "$CAT driver directory missing"
        fi
    done
    
    # Check for specific critical drivers
    echo ""
    echo "  → Windows Driver Coverage:"
    WIN_DRIVERS=("nvme" "ahci" "usb" "network" "graphics")
    for DRV in "${WIN_DRIVERS[@]}"; do
        COUNT=$(find "$ARCHIVE_PATH/Windows" -type f -iname "*$DRV*" 2>/dev/null | wc -l)
        if [ $COUNT -gt 0 ]; then
            echo -e "    ${GREEN}✓${NC} $DRV: $COUNT files"
        else
            echo -e "    ${RED}✗${NC} $DRV: NO FILES"
        fi
    done
    
    echo ""
    echo "  → macOS Kext Coverage:"
    KEXTS=("Lilu" "WhateverGreen" "AppleALC" "VirtualSMC" "IntelMausi" "AirportBrcmFixup")
    for KEXT in "${KEXTS[@]}"; do
        if find "$ARCHIVE_PATH/macOS" -type d -name "${KEXT}*" 2>/dev/null | grep -q .; then
            echo -e "    ${GREEN}✓${NC} $KEXT found"
        else
            echo -e "    ${YELLOW}⚠${NC} $KEXT missing"
        fi
    done
    
    echo ""
    echo "  → Linux Driver Coverage:"
    LIN_DRIVERS=("firmware" "network" "graphics" "wifi")
    for DRV in "${LIN_DRIVERS[@]}"; do
        COUNT=$(find "$ARCHIVE_PATH/Linux" -type f -iname "*$DRV*" 2>/dev/null | wc -l)
        if [ $COUNT -gt 10 ]; then
            echo -e "    ${GREEN}✓${NC} $DRV: $COUNT files"
        else
            echo -e "    ${YELLOW}⚠${NC} $DRV: $COUNT files (may be sparse)"
        fi
    done
    
    echo ""
    echo "  → Asahi (M1/M2 Mac) Coverage:"
    ASAHI_COMPONENTS=("audio" "gpu" "wifi" "bluetooth")
    for COMP in "${ASAHI_COMPONENTS[@]}"; do
        COUNT=$(find "$ARCHIVE_PATH/Asahi" -type f -iname "*$COMP*" 2>/dev/null | wc -l)
        if [ $COUNT -gt 0 ]; then
            echo -e "    ${GREEN}✓${NC} $COMP: $COUNT files"
        else
            echo -e "    ${YELLOW}⚠${NC} $COMP: $COUNT files"
        fi
    done
    
else
    test_result 1 "Driver archive directory missing"
fi

echo ""
echo "=== 6. OPENCORE INTEGRATION ==="
OC_PATH="/media/phantom-orchestrator/UniversalBoot/OpenCore"
if [ -d "$OC_PATH" ]; then
    test_result 0 "OpenCore directory exists"
    
    if [ -f "$OC_PATH/OpenCore.efi" ]; then
        test_result 0 "OpenCore.efi present"
    else
        test_result 1 "OpenCore.efi missing"
    fi
    
    if [ -f "$OC_PATH/config.plist" ]; then
        test_result 0 "config.plist present"
    else
        test_result 1 "config.plist missing"
    fi
else
    test_result 1 "OpenCore directory missing"
fi

echo ""
echo "=== 7. UBUNTU INSTALLATION ==="
UBUNTU_MOUNT="/media/phantom-orchestrator/MultiBootUbuntu1"
if [ -d "$UBUNTU_MOUNT" ]; then
    test_result 0 "Ubuntu partition mounted"
    
    # Check for key directories
    for DIR in "boot" "etc" "usr" "var"; do
        if [ -d "$UBUNTU_MOUNT/$DIR" ]; then
            test_result 0 "Ubuntu $DIR directory present"
        else
            test_result 1 "Ubuntu $DIR directory missing"
        fi
    done
    
    # Check for kernel
    if ls "$UBUNTU_MOUNT/boot/vmlinuz-"* >/dev/null 2>&1; then
        KERNEL=$(ls "$UBUNTU_MOUNT/boot/vmlinuz-"* | head -1 | xargs basename)
        test_result 0 "Linux kernel present ($KERNEL)"
    else
        test_result 1 "Linux kernel missing"
    fi
    
    # Check for initrd
    if ls "$UBUNTU_MOUNT/boot/initrd.img-"* >/dev/null 2>&1; then
        test_result 0 "Initrd present"
    else
        test_result 1 "Initrd missing"
    fi
else
    test_result 1 "Ubuntu partition NOT mounted"
fi

echo ""
echo "=== 8. GRUB CONFIGURATION ==="
GRUB_CFG="/media/phantom-orchestrator/UniversalBoot/grub/grub.cfg"
if [ -f "$GRUB_CFG" ]; then
    test_result 0 "GRUB config exists"
    
    # Check for OS entries
    if grep -q "menuentry.*Windows" "$GRUB_CFG"; then
        test_result 0 "Windows boot entry present"
    else
        test_result 1 "Windows boot entry missing"
    fi
    
    if grep -q "menuentry.*macOS" "$GRUB_CFG"; then
        test_result 0 "macOS boot entry present"
    else
        test_result 1 "macOS boot entry missing"
    fi
    
    if grep -q "menuentry.*Ubuntu" "$GRUB_CFG"; then
        test_result 0 "Ubuntu boot entry present"
    else
        test_result 1 "Ubuntu boot entry missing"
    fi
else
    test_result 1 "GRUB config missing"
fi

echo ""
echo "=== 9. NETWORK HANDLER ==="
NET_HANDLER="/media/phantom-orchestrator/UniversalBoot/boot/network_handler.sh"
if [ -f "$NET_HANDLER" ]; then
    test_result 0 "Network handler script exists"
    
    # Check for WiFi prompt functionality
    if grep -q "wifi_connect" "$NET_HANDLER"; then
        test_result 0 "WiFi connection function present"
    else
        warn_result "WiFi connection function not found"
    fi
    
    # Check for offline fallback
    if grep -q "offline" "$NET_HANDLER"; then
        test_result 0 "Offline fallback present"
    else
        warn_result "Offline fallback not found"
    fi
else
    test_result 1 "Network handler missing"
fi

echo ""
echo "=== 10. HARDWARE DETECTION ==="
HW_DETECT="/media/phantom-orchestrator/UniversalBoot/boot/detect_hardware.sh"
if [ -f "$HW_DETECT" ]; then
    test_result 0 "Hardware detection script exists"
    
    # Check for firmware detection
    if grep -q "firmware" "$HW_DETECT"; then
        test_result 0 "Firmware type detection present"
    else
        test_result 1 "Firmware type detection missing"
    fi
    
    # Check for Apple Silicon detection
    if grep -q -i "apple\|m1\|m2\|arm64" "$HW_DETECT"; then
        test_result 0 "Apple Silicon detection present"
    else
        warn_result "Apple Silicon detection unclear"
    fi
else
    test_result 1 "Hardware detection script missing"
fi

echo ""
echo "=== 11. DRIVER INJECTION ==="
INJECT="/media/phantom-orchestrator/UniversalBoot/boot/inject_drivers.sh"
if [ -f "$INJECT" ]; then
    test_result 0 "Driver injection script exists"
    
    # Check for dynamic loading
    if grep -q "modprobe\|insmod" "$INJECT"; then
        test_result 0 "Dynamic driver loading present"
    else
        warn_result "Dynamic driver loading unclear"
    fi
else
    test_result 1 "Driver injection script missing"
fi

echo ""
echo "=== 12. BOOT MODES SUPPORT ==="
echo "  → Checking boot mode coverage..."

# UEFI support
if [ -d "/media/phantom-orchestrator/UniversalBoot/EFI" ]; then
    test_result 0 "UEFI boot support (EFI directory)"
else
    test_result 1 "UEFI boot support missing"
fi

# BIOS/Legacy support
if [ -f "$GRUB_CFG" ]; then
    test_result 0 "BIOS/Legacy boot support (GRUB)"
else
    test_result 1 "BIOS/Legacy boot support unclear"
fi

# M1/M2 Mac support (Asahi)
if [ -d "$ARCHIVE_PATH/Asahi" ] && [ -n "$(ls -A $ARCHIVE_PATH/Asahi 2>/dev/null)" ]; then
    test_result 0 "M1/M2 Mac support (Asahi drivers)"
else
    test_result 1 "M1/M2 Mac support insufficient"
fi

# Intel Mac support (OpenCore)
if [ -d "$OC_PATH" ] && [ -f "$OC_PATH/OpenCore.efi" ]; then
    test_result 0 "Intel Mac support (OpenCore)"
else
    test_result 1 "Intel Mac support incomplete"
fi

echo ""
echo "=== 13. SPACE AVAILABILITY ==="
USED=$(df -h /media/phantom-orchestrator/UniversalBoot | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $USED -lt 80 ]; then
    test_result 0 "Archive has room for additional drivers (${USED}% used)"
elif [ $USED -lt 95 ]; then
    warn_result "Archive getting full (${USED}% used)"
else
    test_result 1 "Archive nearly full (${USED}% used)"
fi

echo ""
echo "======================================"
echo "VALIDATION SUMMARY"
echo "======================================"
echo -e "${GREEN}PASSED: $PASS${NC}"
echo -e "${YELLOW}WARNINGS: $WARN${NC}"
echo -e "${RED}FAILED: $FAIL${NC}"
echo ""

TOTAL_DRIVERS=$(find /media/phantom-orchestrator/UniversalBoot/DriverArchive -type f 2>/dev/null | wc -l)
ARCHIVE_SIZE=$(du -sh /media/phantom-orchestrator/UniversalBoot/DriverArchive 2>/dev/null | cut -f1)

echo "Driver Archive: $TOTAL_DRIVERS files ($ARCHIVE_SIZE)"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ SYSTEM READY FOR BOOT TESTING${NC}"
    exit 0
elif [ $FAIL -lt 5 ]; then
    echo -e "${YELLOW}⚠ SYSTEM PARTIALLY READY - Some fixes needed${NC}"
    exit 1
else
    echo -e "${RED}✗ SYSTEM NOT READY - Major issues detected${NC}"
    exit 2
fi
