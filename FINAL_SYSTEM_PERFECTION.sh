#!/bin/bash
echo "=== MULTIBOOT SYSTEM PERFECTION CHECKLIST ==="

echo "1. Checking Ubuntu installation on sdb5..."
mountpoint -q /run/media/phantom-orchestrator/MultiBoot_Ubuntu && echo "✓ Ubuntu mounted" || echo "✗ Ubuntu needs installation"

echo "2. Checking boot integration..."
[ -f /run/media/phantom-orchestrator/MultiBoot_System/universal_boot_manager.py ] && echo "✓ Boot manager present" || echo "✗ Boot manager missing"

echo "3. Checking driver archive..."
[ -d /run/media/phantom-orchestrator/MultiBoot_Archive/DriverArchive ] && echo "✓ Archive exists ($(du -sh /run/media/phantom-orchestrator/MultiBoot_Archive/DriverArchive 2>/dev/null | cut -f1))" || echo "✗ Archive missing"

echo "4. Checking OpenCore integration..."
[ -d /run/media/phantom-orchestrator/MultiBoot_System/OpenCore ] && echo "✓ OpenCore present" || echo "✗ OpenCore needs setup"

echo "5. Checking Asahi integration..."
[ -d /run/media/phantom-orchestrator/MultiBoot_System/AsahiLinux ] && echo "✓ Asahi present" || echo "✗ Asahi needs setup"

echo "6. Testing hardware detection..."
python3 -c "import platform; print(f'✓ Platform detection: {platform.machine()}')"

echo "7. Checking EFI partition..."
lsblk -f /dev/sdb1 2>/dev/null && echo "✓ EFI partition exists" || echo "✗ EFI issue"

echo "=== WHAT STILL NEEDS WORK ==="
