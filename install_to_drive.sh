#!/bin/bash
# Install Universal MultiBoot to drive

set -e

WORKSPACE="/media/phantom-orchestrator/BitcoinNode/AI Projects/MultiBoot"
DRIVE="/dev/sdc"
UNIVERSALBOOT_PART="${DRIVE}4"
EFI_PART="${DRIVE}1"

echo "========================================"
echo "  UNIVERSAL MULTIBOOT INSTALLER"
echo "========================================"
echo ""
echo "This will install to:"
echo "  - ${UNIVERSALBOOT_PART} (UniversalBoot partition)"
echo "  - ${EFI_PART} (EFI partition - GRUB)"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "=== Step 1: Mount UniversalBoot partition ==="
sudo mkdir -p /mnt/universalboot
sudo mount ${UNIVERSALBOOT_PART} /mnt/universalboot
echo "✅ Mounted at /mnt/universalboot"

echo ""
echo "=== Step 2: Copy project files ==="
sudo cp -r "${WORKSPACE}"/* /mnt/universalboot/
echo "✅ Files copied"

echo ""
echo "=== Step 3: Set permissions ==="
sudo chown -R root:root /mnt/universalboot/
sudo chmod -R 755 /mnt/universalboot/BootScripts/
sudo chmod +x /mnt/universalboot/BootScripts/*.py
echo "✅ Permissions set"

echo ""
echo "=== Step 4: Mount EFI partition ==="
sudo mkdir -p /mnt/multiboot_efi
sudo mount ${EFI_PART} /mnt/multiboot_efi
echo "✅ EFI mounted"

echo ""
echo "=== Step 5: Install GRUB ==="
sudo grub-install --target=x86_64-efi \
                  --efi-directory=/mnt/multiboot_efi \
                  --boot-directory=/mnt/multiboot_efi/boot \
                  --bootloader-id=UniversalMultiBoot \
                  --removable
echo "✅ GRUB installed"

echo ""
echo "=== Step 6: Create GRUB config ==="
sudo tee /mnt/multiboot_efi/boot/grub/grub.cfg > /dev/null << 'GRUBEOF'
set timeout=10
set default=0

menuentry "Universal MultiBoot" {
    insmod ext2
    search --no-floppy --fs-uuid --set=root $(blkid -s UUID -o value ${UNIVERSALBOOT_PART})
    linux /BootScripts/boot_menu.py
}

menuentry "Reboot" {
    reboot
}

menuentry "Power Off" {
    halt
}
GRUBEOF
echo "✅ GRUB config created"

echo ""
echo "=== Step 7: Show installation ==="
echo "UniversalBoot partition:"
ls -lh /mnt/universalboot/
echo ""
echo "EFI partition:"
ls -lh /mnt/multiboot_efi/

echo ""
echo "========================================"
echo "  ✅ INSTALLATION COMPLETE!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Install Ubuntu to ${DRIVE}5"
echo "2. Download drivers to populate archive"
echo "3. Reboot and test!"
echo ""

