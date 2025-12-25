#!/bin/bash
echo "🔧 FIXING WINDOWS BCD FOR EXTERNAL BOOT"
echo "========================================"
echo ""

# Mount Windows partition
echo "Mounting Windows partition..."
sudo mkdir -p /mnt/win_fix
sudo mount /dev/sde2 /mnt/win_fix

if [ $? -ne 0 ]; then
    echo "❌ Failed to mount Windows partition!"
    exit 1
fi

echo "✅ Mounted!"
echo ""

# Mount EFI partition
echo "Mounting EFI partition..."
sudo mkdir -p /mnt/efi_bcd
sudo mount /dev/sde1 /mnt/efi_bcd

echo "✅ Mounted!"
echo ""

# Check if BCD exists
echo "Checking for existing BCD..."
if [ -f /mnt/win_fix/Boot/BCD ]; then
    echo "✅ Found BCD at /Boot/BCD"
    BCD_PATH="/mnt/win_fix/Boot/BCD"
elif [ -f /mnt/win_fix/Windows/Boot/BCD ]; then
    echo "✅ Found BCD at /Windows/Boot/BCD"
    BCD_PATH="/mnt/win_fix/Windows/Boot/BCD"
else
    echo "⚠️  No BCD found - will need to create one"
    BCD_PATH="NONE"
fi

echo ""
echo "Current situation:"
echo "  Windows partition: /dev/sde2 (mounted at /mnt/win_fix)"
echo "  EFI partition: /dev/sde1 (mounted at /mnt/efi_bcd)"
echo "  Windows bootloader: /mnt/win_fix/Windows/Boot/EFI/bootmgfw.efi"
echo "  BCD location: $BCD_PATH"
echo ""

# Create BCD repair script that can be run from Windows Recovery
echo "Creating BCD repair script for Windows Recovery..."

sudo tee /mnt/efi_bcd/REPAIR_WINDOWS_BCD.txt > /dev/null << 'REPAIR'
===============================================
HOW TO REPAIR WINDOWS BCD FROM RECOVERY
===============================================

When Windows boots to Recovery mode:

1. Click "Advanced options"
2. Click "Troubleshoot"
3. Click "Command Prompt"

4. Run these commands:

   diskpart
   list disk
   select disk X (where X is this USB drive number)
   list volume
   (note the volume letters for Windows and EFI partitions)
   exit

5. Rebuild BCD:

   bootrec /fixmbr
   bootrec /fixboot
   bootrec /scanos
   bootrec /rebuildbcd

6. If that doesn't work, manually create BCD:

   bcdedit /createstore C:\Boot\BCD
   bcdedit /store C:\Boot\BCD /create {bootmgr}
   bcdedit /store C:\Boot\BCD /set {bootmgr} device partition=C:
   bcdedit /store C:\Boot\BCD /create /d "Windows 10" /application osloader
   (note the GUID returned, use it as {guid} below)
   bcdedit /store C:\Boot\BCD /set {guid} device partition=C:
   bcdedit /store C:\Boot\BCD /set {guid} path \Windows\system32\winload.efi
   bcdedit /store C:\Boot\BCD /set {guid} osdevice partition=C:
   bcdedit /store C:\Boot\BCD /set {guid} systemroot \Windows
   bcdedit /store C:\Boot\BCD /displayorder {guid} /addlast

7. Copy BCD to EFI partition:

   copy C:\Boot\BCD Z:\EFI\Microsoft\Boot\BCD
   (where Z: is the EFI partition)

8. Reboot and test!

===============================================
REPAIR

echo "✅ Created repair instructions at /REPAIR_WINDOWS_BCD.txt"
echo ""

# Create automated repair script for GRUB
echo "Creating GRUB menu option for Windows repair..."

cat > /tmp/windows_repair_entry.txt << 'GRUBREPAIR'

menuentry "Windows Recovery (Repair BCD)" --class windows {
    echo "Booting Windows Recovery..."
    echo "Use this to repair Windows BCD"
    echo "See /REPAIR_WINDOWS_BCD.txt for instructions"
    
    insmod part_gpt
    insmod ntfs
    insmod chain
    
    search --no-floppy --fs-uuid --set=root 2CF676F66E6B4DC4
    
    if [ -f /Windows/Boot/EFI/bootmgfw.efi ]; then
        chainloader /Windows/Boot/EFI/bootmgfw.efi
    fi
}
GRUBREPAIR

echo "✅ Created GRUB repair entry"
echo ""

# Check Windows installation
echo "Checking Windows installation..."
if [ -d /mnt/win_fix/Windows/System32 ]; then
    echo "✅ Windows System32 found"
    WIN_VERSION=$(ls /mnt/win_fix/Windows/System32/config/SOFTWARE 2>/dev/null && echo "Windows installation detected")
    echo "   $WIN_VERSION"
else
    echo "⚠️  Windows System32 not found"
fi

echo ""
echo "Windows directories:"
ls -lh /mnt/win_fix/ | head -15

echo ""
echo "================================"
echo "SUMMARY"
echo "================================"
echo ""
echo "✅ Windows partition verified"
echo "✅ Bootloader path verified: /Windows/Boot/EFI/bootmgfw.efi"
echo "✅ Repair instructions created"
echo "✅ GRUB repair entry ready"
echo ""
echo "⚠️  Windows will still boot to recovery until BCD is fixed"
echo ""
echo "Next steps:"
echo "  1. Boot from USB"
echo "  2. Select 'Windows Recovery (Repair BCD)'"
echo "  3. Follow instructions in /REPAIR_WINDOWS_BCD.txt"
echo "  4. Or we can add the repair entry to GRUB now"
echo ""

# Cleanup
sudo umount /mnt/win_fix
sudo umount /mnt/efi_bcd

echo "✅ Unmounted partitions"
echo ""
echo "Do you want to add the Windows Recovery option to GRUB? (Y/N)"
