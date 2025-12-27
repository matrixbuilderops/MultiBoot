#!/bin/bash
# Comprehensive Compatibility Testing for All Platforms

echo "=========================================="
echo "MULTIBOOT COMPREHENSIVE COMPATIBILITY TEST"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Test 1: Syntax validation of all scripts
echo "[TEST 1] Validating script syntax..."
for script in /media/phantom-orchestrator/UniversalBoot/boot/*.sh; do
    if [ -f "$script" ]; then
        bash -n "$script" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "  ❌ SYNTAX ERROR: $script"
            ((ERRORS++))
        else
            echo "  ✓ $script"
        fi
    fi
done

# Test 2: Check all path references
echo ""
echo "[TEST 2] Validating path references..."
REQUIRED_PATHS=(
    "/media/phantom-orchestrator/UniversalBoot"
    "/media/phantom-orchestrator/UniversalBoot/boot"
    "/media/phantom-orchestrator/UniversalBoot/drivers"
    "/media/phantom-orchestrator/UniversalBoot/drivers/windows"
    "/media/phantom-orchestrator/UniversalBoot/drivers/macos/kexts"
    "/media/phantom-orchestrator/UniversalBoot/drivers/linux"
    "/media/phantom-orchestrator/UniversalBoot/drivers/asahi"
)

for path in "${REQUIRED_PATHS[@]}"; do
    if [ ! -d "$path" ]; then
        echo "  ❌ MISSING: $path"
        ((ERRORS++))
    else
        echo "  ✓ $path"
    fi
done

# Test 3: M1/M2/M3 Mac compatibility checks
echo ""
echo "[TEST 3] M1/M2/M3 Mac compatibility..."
# Check for ARM64 specific drivers
ARM_KEXTS=$(find /media/phantom-orchestrator/UniversalBoot/drivers/macos/kexts -name "*ARM*" -o -name "*Apple*" 2>/dev/null | wc -l)
if [ $ARM_KEXTS -lt 5 ]; then
    echo "  ⚠️  WARNING: Only $ARM_KEXTS ARM-specific kexts found"
    ((WARNINGS++))
else
    echo "  ✓ Found $ARM_KEXTS ARM-specific kexts"
fi

# Check Asahi Linux drivers
ASAHI_DRIVERS=$(find /media/phantom-orchestrator/UniversalBoot/drivers/asahi -type f 2>/dev/null | wc -l)
if [ $ASAHI_DRIVERS -lt 10 ]; then
    echo "  ⚠️  WARNING: Only $ASAHI_DRIVERS Asahi drivers found"
    ((WARNINGS++))
else
    echo "  ✓ Found $ASAHI_DRIVERS Asahi drivers"
fi

# Test 4: Pre-M1 Intel Mac compatibility
echo ""
echo "[TEST 4] Pre-M1 Intel Mac compatibility..."
INTEL_KEXTS=$(find /media/phantom-orchestrator/UniversalBoot/drivers/macos/kexts -name "*Intel*" -o -name "*Lilu*" -o -name "*WhateverGreen*" 2>/dev/null | wc -l)
if [ $INTEL_KEXTS -lt 10 ]; then
    echo "  ⚠️  WARNING: Only $INTEL_KEXTS Intel Mac kexts found"
    ((WARNINGS++))
else
    echo "  ✓ Found $INTEL_KEXTS Intel Mac kexts"
fi

# Test 5: UEFI compatibility
echo ""
echo "[TEST 5] UEFI compatibility..."
if [ ! -d "/media/phantom-orchestrator/UniversalBoot/EFI" ]; then
    echo "  ❌ ERROR: Missing EFI directory"
    ((ERRORS++))
else
    echo "  ✓ EFI directory exists"
    
    # Check for OpenCore
    if [ ! -f "/media/phantom-orchestrator/UniversalBoot/EFI/OC/OpenCore.efi" ]; then
        echo "  ⚠️  WARNING: OpenCore.efi not found at expected location"
        ((WARNINGS++))
    else
        echo "  ✓ OpenCore.efi found"
    fi
fi

# Test 6: BIOS compatibility
echo ""
echo "[TEST 6] BIOS/Legacy compatibility..."
# Check for GRUB
if command -v grub-install &>/dev/null; then
    echo "  ✓ GRUB available"
else
    echo "  ⚠️  WARNING: GRUB not found"
    ((WARNINGS++))
fi

# Test 7: Hardware detection logic
echo ""
echo "[TEST 7] Hardware detection logic..."
if [ -f "/media/phantom-orchestrator/UniversalBoot/boot/detect_hardware.sh" ]; then
    # Check if it detects firmware type
    if grep -q "efi" /media/phantom-orchestrator/UniversalBoot/boot/detect_hardware.sh; then
        echo "  ✓ EFI detection present"
    else
        echo "  ❌ ERROR: Missing EFI detection"
        ((ERRORS++))
    fi
    
    # Check if it detects CPU architecture
    if grep -q "arm\|aarch64\|x86_64" /media/phantom-orchestrator/UniversalBoot/boot/detect_hardware.sh; then
        echo "  ✓ CPU architecture detection present"
    else
        echo "  ❌ ERROR: Missing CPU architecture detection"
        ((ERRORS++))
    fi
else
    echo "  ❌ ERROR: detect_hardware.sh missing"
    ((ERRORS++))
fi

# Test 8: Driver archive completeness
echo ""
echo "[TEST 8] Driver archive completeness..."
TOTAL_DRIVERS=$(find /media/phantom-orchestrator/UniversalBoot/drivers -type f 2>/dev/null | wc -l)
echo "  Total drivers in archive: $TOTAL_DRIVERS"

WIN_DRIVERS=$(find /media/phantom-orchestrator/UniversalBoot/drivers/windows -type f 2>/dev/null | wc -l)
MAC_DRIVERS=$(find /media/phantom-orchestrator/UniversalBoot/drivers/macos -type f 2>/dev/null | wc -l)
LINUX_DRIVERS=$(find /media/phantom-orchestrator/UniversalBoot/drivers/linux -type f 2>/dev/null | wc -l)

echo "  - Windows: $WIN_DRIVERS drivers"
echo "  - macOS: $MAC_DRIVERS drivers"
echo "  - Linux: $LINUX_DRIVERS drivers"

if [ $TOTAL_DRIVERS -lt 100 ]; then
    echo "  ⚠️  WARNING: Driver count seems low for comprehensive coverage"
    ((WARNINGS++))
fi

# Test 9: Internet fallback mechanism
echo ""
echo "[TEST 9] Internet fallback mechanism..."
if grep -r "wget\|curl" /media/phantom-orchestrator/UniversalBoot/boot/*.sh &>/dev/null; then
    echo "  ✓ Internet download capability present"
else
    echo "  ⚠️  WARNING: No internet fallback detected"
    ((WARNINGS++))
fi

# Test 10: Format compatibility
echo ""
echo "[TEST 10] File format compatibility..."
# Check for DOS line endings (problematic on Unix)
DOS_FILES=$(find /media/phantom-orchestrator/UniversalBoot/boot -name "*.sh" -exec file {} \; | grep -c "CRLF" 2>/dev/null)
if [ $DOS_FILES -gt 0 ]; then
    echo "  ⚠️  WARNING: $DOS_FILES files have DOS line endings"
    ((WARNINGS++))
else
    echo "  ✓ No DOS line ending issues"
fi

# Summary
echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "Total Errors: $ERRORS"
echo "Total Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ ALL TESTS PASSED - System ready for deployment!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  TESTS PASSED WITH WARNINGS - Review recommended"
    exit 0
else
    echo "❌ TESTS FAILED - Issues must be resolved"
    exit 1
fi
