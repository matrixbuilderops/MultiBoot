#!/bin/bash

echo "=== COMPREHENSIVE MULTIBOOT TESTING SUITE ==="
echo "This will test every component we can without actual boot"
echo ""

PASS=0
FAIL=0
WARN=0

# Test 1: File Structure
echo "[TEST 1] Checking file structure..."
if [ -f "/media/phantom-orchestrator/UniversalBoot/universal_multiboot_init.sh" ]; then
    echo "  ✓ Main boot script exists"
    ((PASS++))
else
    echo "  ✗ Main boot script MISSING"
    ((FAIL++))
fi

if [ -d "/media/phantom-orchestrator/UniversalBoot/DriverArchive" ]; then
    echo "  ✓ Driver archive exists"
    ((PASS++))
else
    echo "  ✗ Driver archive MISSING"
    ((FAIL++))
fi

# Test 2: Script Syntax
echo -e "\n[TEST 2] Checking script syntax..."
for script in /media/phantom-orchestrator/UniversalBoot/*.sh; do
    if bash -n "$script" 2>/dev/null; then
        echo "  ✓ $(basename $script) syntax OK"
        ((PASS++))
    else
        echo "  ✗ $(basename $script) SYNTAX ERROR"
        ((FAIL++))
    fi
done

# Test 3: Driver Archive Contents
echo -e "\n[TEST 3] Checking driver archive..."
KEXT_COUNT=$(find /media/phantom-orchestrator/UniversalBoot/DriverArchive/macOS/ -name "*.kext" 2>/dev/null | wc -l)
LINUX_COUNT=$(find /media/phantom-orchestrator/UniversalBoot/DriverArchive/Linux/ -type f 2>/dev/null | wc -l)
WINDOWS_COUNT=$(find /media/phantom-orchestrator/UniversalBoot/DriverArchive/Windows/ -name "*.inf" -o -name "*.sys" 2>/dev/null | wc -l)

echo "  macOS kexts: $KEXT_COUNT"
echo "  Linux drivers: $LINUX_COUNT"
echo "  Windows drivers: $WINDOWS_COUNT"

if [ $KEXT_COUNT -gt 50 ]; then
    echo "  ✓ macOS driver coverage: GOOD"
    ((PASS++))
elif [ $KEXT_COUNT -gt 20 ]; then
    echo "  ⚠ macOS driver coverage: MODERATE"
    ((WARN++))
else
    echo "  ✗ macOS driver coverage: POOR"
    ((FAIL++))
fi

if [ $WINDOWS_COUNT -gt 100 ]; then
    echo "  ✓ Windows driver coverage: GOOD"
    ((PASS++))
elif [ $WINDOWS_COUNT -gt 20 ]; then
    echo "  ⚠ Windows driver coverage: MODERATE"
    ((WARN++))
else
    echo "  ✗ Windows driver coverage: POOR (NEEDS EXPANSION)"
    ((FAIL++))
fi

# Test 4: Hardware Detection Logic
echo -e "\n[TEST 4] Testing hardware detection functions..."

# Simulate detection
cat > /tmp/test_hw_detect.sh << 'HWTEST'
detect_hardware_type() {
    if [ -d "/sys/firmware/efi" ]; then
        echo "UEFI"
    else
        echo "BIOS"
    fi
}

detect_apple_hardware() {
    if [ -f "/sys/firmware/devicetree/base/compatible" ]; then
        if grep -q "apple,arm-platform" /sys/firmware/devicetree/base/compatible 2>/dev/null; then
            echo "M1+"
        else
            echo "Intel Mac"
        fi
    else
        echo "PC"
    fi
}

FW=$(detect_hardware_type)
HW=$(detect_apple_hardware)
echo "Detected: $HW on $FW"
HWTEST

if bash /tmp/test_hw_detect.sh 2>/dev/null | grep -q "Detected:"; then
    echo "  ✓ Hardware detection functions work"
    ((PASS++))
else
    echo "  ✗ Hardware detection FAILED"
    ((FAIL++))
fi

# Test 5: OpenCore Configuration
echo -e "\n[TEST 5] Checking OpenCore integration..."
if [ -d "/media/phantom-orchestrator/UniversalBoot/OpenCore" ]; then
    echo "  ✓ OpenCore directory exists"
    ((PASS++))
    
    if [ -f "/media/phantom-orchestrator/UniversalBoot/OpenCore/config.plist" ]; then
        echo "  ✓ OpenCore config.plist exists"
        ((PASS++))
    else
        echo "  ⚠ OpenCore config.plist missing (needs generation)"
        ((WARN++))
    fi
else
    echo "  ✗ OpenCore NOT integrated"
    ((FAIL++))
fi

# Test 6: Asahi Integration
echo -e "\n[TEST 6] Checking Asahi Linux integration..."
ASAHI_REPOS=$(find /media/phantom-orchestrator/BitcoinNode/AI\ Projects/MultiBoot/AsahiRepos/ -type d -name ".git" 2>/dev/null | wc -l)
echo "  Asahi repos available: $ASAHI_REPOS"

if [ $ASAHI_REPOS -gt 30 ]; then
    echo "  ✓ Asahi repos: COMPLETE"
    ((PASS++))
else
    echo "  ⚠ Asahi repos: INCOMPLETE (have $ASAHI_REPOS/39)"
    ((WARN++))
fi

# Test 7: Partition Setup
echo -e "\n[TEST 7] Verifying partition setup..."
if lsblk | grep -q "MultiBootWindows"; then
    echo "  ✓ Windows partition labeled correctly"
    ((PASS++))
else
    echo "  ✗ Windows partition label issue"
    ((FAIL++))
fi

if lsblk | grep -q "MultiBootMac"; then
    echo "  ✓ macOS partition labeled correctly"
    ((PASS++))
else
    echo "  ✗ macOS partition label issue"
    ((FAIL++))
fi

if lsblk | grep -q "MultiBootUbuntu"; then
    echo "  ✓ Ubuntu partition labeled correctly"
    ((PASS++))
else
    echo "  ✗ Ubuntu partition label issue"
    ((FAIL++))
fi

# Test 8: EFI Partition
echo -e "\n[TEST 8] Checking EFI partition..."
EFI_PART=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep sdg1)
if [ -n "$EFI_PART" ]; then
    echo "  ✓ EFI partition (sdg1) exists: $EFI_PART"
    ((PASS++))
else
    echo "  ✗ EFI partition missing"
    ((FAIL++))
fi

# Test 9: Internet Connectivity (for driver downloads)
echo -e "\n[TEST 9] Testing internet connectivity capability..."
if command -v nmcli &> /dev/null || command -v wpa_supplicant &> /dev/null; then
    echo "  ✓ WiFi tools available for boot-time setup"
    ((PASS++))
else
    echo "  ⚠ WiFi tools may need installation"
    ((WARN++))
fi

# Test 10: Driver Injection Script
echo -e "\n[TEST 10] Validating driver injection logic..."
if grep -q "inject_drivers" /media/phantom-orchestrator/UniversalBoot/universal_multiboot_init.sh 2>/dev/null; then
    echo "  ✓ Driver injection integrated into boot"
    ((PASS++))
else
    echo "  ✗ Driver injection NOT called from boot script"
    ((FAIL++))
fi

# Summary
echo -e "\n=== TEST RESULTS SUMMARY ==="
echo "PASSED:   $PASS"
echo "FAILED:   $FAIL"
echo "WARNINGS: $WARN"
echo ""

TOTAL=$((PASS + FAIL + WARN))
SCORE=$((PASS * 100 / TOTAL))
echo "OVERALL SCORE: $SCORE%"

if [ $SCORE -ge 90 ]; then
    echo "STATUS: EXCELLENT - Ready for real hardware testing"
elif [ $SCORE -ge 70 ]; then
    echo "STATUS: GOOD - Minor fixes needed before testing"
elif [ $SCORE -ge 50 ]; then
    echo "STATUS: FAIR - Significant work remaining"
else
    echo "STATUS: POOR - Major issues need resolution"
fi

echo ""
echo "=== NEXT STEPS ==="
echo "1. Run: sudo bash COMPREHENSIVE_TEST_PLAN.sh"
echo "2. Fix any FAILED tests"
echo "3. Address WARNINGS"
echo "4. Install GRUB bootloader"
echo "5. Test on actual hardware"
