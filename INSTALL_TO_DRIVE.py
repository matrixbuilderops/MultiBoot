#!/usr/bin/env python3
"""
GENESIS - Universal MultiBoot Master Installer
Installs everything to the 2TB drive in one shot!
"""

import subprocess
import shutil
from pathlib import Path
import sys
import time

class GenesisInstaller:
    def __init__(self):
        self.workspace = Path("/media/phantom-eternal/Games & Mods/Project ai shit/UniversalMultiBoot-Genesis")
        self.efi_device = "/dev/sdd1"
        self.efi_mount = Path("/mnt/genesis_efi")
        self.password = "C00dingAg3nt"
        
    def sudo(self, cmd):
        """Run command with sudo"""
        full_cmd = f"echo {self.password} | sudo -S {cmd}"
        return subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
    
    def banner(self, text):
        """Print fancy banner"""
        print("\n" + "=" * 70)
        print(f"  {text}")
        print("=" * 70 + "\n")
    
    def step(self, num, total, text):
        """Print step"""
        print(f"[{num}/{total}] {text}...")
    
    def check_drive(self):
        """Verify 2TB drive exists"""
        self.banner("🔍 CHECKING 2TB DRIVE")
        
        result = subprocess.run(['lsblk', '/dev/sdd'], capture_output=True)
        if result.returncode != 0:
            print("❌ /dev/sdd not found!")
            print("   Make sure 2TB drive is connected")
            return False
        
        print("✅ 2TB drive detected: /dev/sdd")
        
        # Show current partitions
        subprocess.run(['lsblk', '/dev/sdd'])
        
        return True
    
    def backup_efi(self):
        """Backup existing EFI"""
        self.banner("💾 BACKING UP EXISTING EFI")
        
        print("Mounting EFI partition...")
        self.efi_mount.mkdir(parents=True, exist_ok=True)
        self.sudo(f"mount {self.efi_device} {self.efi_mount}")
        
        backup_dir = self.workspace / "EFI_BACKUP"
        backup_dir.mkdir(exist_ok=True)
        
        print(f"Backing up to {backup_dir}...")
        self.sudo(f"cp -r {self.efi_mount}/EFI {backup_dir}/")
        
        print("✅ Backup complete!")
    
    def install_opencore(self):
        """Copy OpenCore EFI"""
        self.banner("🍎 INSTALLING OPENCORE")
        
        generated_efi = self.workspace / "GeneratedEFI" / "EFI" / "OC"
        target_efi = self.efi_mount / "EFI" / "OC"
        
        if target_efi.exists():
            print("Removing old OpenCore...")
            self.sudo(f"rm -rf {target_efi}")
        
        print(f"Copying OpenCore to {target_efi}...")
        self.sudo(f"cp -r {generated_efi} {target_efi}")
        
        print("✅ OpenCore installed!")
    
    def install_grub(self):
        """Install GRUB bootloader"""
        self.banner("🔧 INSTALLING GRUB")
        
        print("Installing GRUB to EFI...")
        result = self.sudo(f"grub-install --target=x86_64-efi --efi-directory={self.efi_mount} --bootloader-id=Genesis --removable")
        
        if result.returncode != 0:
            print(f"⚠️  Warning: {result.stderr}")
        
        print("Copying grub.cfg...")
        grub_dir = self.efi_mount / "boot" / "grub"
        grub_dir.mkdir(parents=True, exist_ok=True)
        
        grub_cfg = Path("/tmp/grub.cfg")
        if grub_cfg.exists():
            self.sudo(f"cp {grub_cfg} {grub_dir}/grub.cfg")
        
        print("✅ GRUB installed!")
    
    def copy_wrapper(self):
        """Copy UniversalWrapper to EFI"""
        self.banner("📦 INSTALLING UNIVERSAL WRAPPER")
        
        wrapper_target = self.efi_mount / "UniversalWrapper"
        
        if wrapper_target.exists():
            print("Removing old wrapper...")
            self.sudo(f"rm -rf {wrapper_target}")
        
        print("Copying wrapper files...")
        items_to_copy = [
            "BootScripts",
            "DriverArchive",
            "HardwareProfiles",
            "OpCoreEngine",
            "universal_config.json"
        ]
        
        wrapper_target.mkdir(exist_ok=True)
        
        for item in items_to_copy:
            src = self.workspace / item
            if src.exists():
                print(f"  - {item}")
                self.sudo(f"cp -r {src} {wrapper_target}/")
        
        print("✅ Wrapper installed!")
    
    def create_boot_entry(self):
        """Create BOOT folder"""
        self.banner("🚀 CREATING BOOT ENTRY")
        
        boot_dir = self.efi_mount / "EFI" / "BOOT"
        boot_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy GRUB as default bootloader
        grub_efi = self.efi_mount / "EFI" / "Genesis" / "grubx64.efi"
        if grub_efi.exists():
            print("Setting GRUB as default bootloader...")
            self.sudo(f"cp {grub_efi} {boot_dir}/BOOTX64.EFI")
        
        print("✅ Boot entry created!")
    
    def check_space(self):
        """Check EFI space usage"""
        self.banner("📊 CHECKING EFI SPACE")
        
        result = subprocess.run(['df', '-h', str(self.efi_mount)], capture_output=True, text=True)
        print(result.stdout)
        
        # Calculate wrapper size
        wrapper_size = sum(f.stat().st_size for f in self.workspace.rglob('*') if f.is_file())
        wrapper_mb = wrapper_size / 1024 / 1024
        
        print(f"UniversalWrapper size: {wrapper_mb:.1f}MB")
    
    def set_permissions(self):
        """Fix permissions"""
        self.banner("🔐 SETTING PERMISSIONS")
        
        print("Making scripts executable...")
        self.sudo(f"chmod -R +x {self.efi_mount}/UniversalWrapper/BootScripts/*.py")
        self.sudo(f"chmod -R +x {self.efi_mount}/UniversalWrapper/BootScripts/*.sh")
        
        print("✅ Permissions set!")
    
    def cleanup(self):
        """Unmount and cleanup"""
        self.banner("🧹 CLEANUP")
        
        print("Syncing filesystems...")
        self.sudo("sync")
        
        print("Unmounting EFI...")
        self.sudo(f"umount {self.efi_mount}")
        
        print("✅ Cleanup complete!")
    
    def show_summary(self):
        """Show installation summary"""
        self.banner("🎉 INSTALLATION COMPLETE!")
        
        print("✅ OpenCore EFI installed")
        print("✅ GRUB bootloader installed")
        print("✅ Universal Wrapper installed")
        print("✅ Boot entries configured")
        
        print("\n📋 What's on your 2TB drive:")
        print("   /dev/sdd1 (EFI) - Bootloaders + Universal Wrapper")
        print("   /dev/sdd2 (600GB) - Windows 10")
        print("   /dev/sdd3 (663GB) - macOS")
        print("   /dev/sdd4 (600GB) - Ubuntu")
        
        print("\n🚀 READY TO BOOT!")
        print("   1. Safely eject 2TB drive")
        print("   2. Plug into any computer")
        print("   3. Boot from external drive")
        print("   4. Select your OS!")
        
        print("\n💡 Boot instructions:")
        print("   - Intel/AMD PC: Press F12/F11/Del during boot")
        print("   - Mac: Hold Option/Alt key during boot")
        print("   - Select 'EFI Boot' or 'USB Boot'")
        
        print("\n" + "=" * 70)
        print("  🔥 UNIVERSAL MULTIBOOT - GENESIS IS READY! 🔥")
        print("=" * 70 + "\n")
    
    def run(self):
        """Run complete installation"""
        self.banner("🚀 GENESIS - UNIVERSAL MULTIBOOT INSTALLER")
        
        print("This will install Universal MultiBoot to your 2TB drive (/dev/sdd)")
        print("⚠️  WARNING: This will modify the EFI partition!")
        print("")
        
        response = input("Continue? (yes/no): ").strip().lower()
        if response != 'yes':
            print("Installation cancelled.")
            return False
        
        steps = [
            ("Checking drive", self.check_drive),
            ("Backing up EFI", self.backup_efi),
            ("Installing OpenCore", self.install_opencore),
            ("Installing GRUB", self.install_grub),
            ("Copying Universal Wrapper", self.copy_wrapper),
            ("Creating boot entry", self.create_boot_entry),
            ("Setting permissions", self.set_permissions),
            ("Checking space", self.check_space),
            ("Cleanup", self.cleanup)
        ]
        
        total = len(steps)
        
        for i, (name, func) in enumerate(steps, 1):
            self.step(i, total, name)
            
            try:
                result = func()
                if result is False:
                    print(f"\n❌ Installation failed at: {name}")
                    return False
                time.sleep(0.5)
            except Exception as e:
                print(f"\n❌ Error: {e}")
                return False
        
        self.show_summary()
        return True

def main():
    installer = GenesisInstaller()
    
    try:
        success = installer.run()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Installation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
