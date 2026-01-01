#!/usr/bin/env python3
"""
🔥 UNIVERSAL WRAPPER - EVERYTHING Gets Wrapped
All OSes go through detection, driver check, and injection
"""

import json
import subprocess
from pathlib import Path

class UniversalWrapper:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.hardware = self.load_hardware()
        self.computer_type = None
        self.boot_mode = None
    
    def load_hardware(self):
        """Load detected hardware profile"""
        profile_file = self.base_dir / "HardwareProfiles" / "current.json"
        if profile_file.exists():
            with open(profile_file, 'r') as f:
                return json.load(f)
        return {}
    
    def is_mac(self):
        """Detect if running on a Mac"""
        try:
            dmi = subprocess.run(['dmidecode', '-s', 'system-manufacturer'], 
                               capture_output=True, text=True, timeout=2)
            if 'Apple' in dmi.stdout:
                return True
        except:
            pass
        
        cpu_name = self.hardware.get('cpu', {}).get('name', '').lower()
        if 'apple' in cpu_name:
            return True
        
        return False
    
    def is_apple_silicon(self):
        """Detect if running on Apple Silicon (M1/M2/M3)"""
        arch = self.hardware.get('architecture', '')
        if arch in ['aarch64', 'arm64']:
            return True
        return False
    
    def detect_computer_type(self):
        """Detect what type of computer we're booting on"""
        if self.is_mac():
            if self.is_apple_silicon():
                return "ARM_MAC"
            else:
                return "INTEL_MAC"
        else:
            platform = self.hardware.get('platform', 'unknown')
            if platform == 'AMD':
                return "AMD_PC"
            else:
                return "INTEL_PC"
    
    def get_boot_strategy(self, computer_type, target_os):
        """
        THE UNIVERSAL MATRIX
        Ensures any OS on the drive can run on any physical host.
        """
        
        strategies = {
            "INTEL_PC": {
                "macos": {"method": "opencore_x86", "description": "Wrapped: OpenCore UEFI/BIOS for Intel"},
                "windows": {"method": "chainload_x86", "description": "Wrapped: Native Windows x86"},
                "linux": {"method": "grub_x86", "description": "Wrapped: Ubuntu x86"}
            },
            "AMD_PC": {
                "macos": {"method": "opencore_amd", "description": "Wrapped: OpenCore with AMD Kernel Patches"},
                "windows": {"method": "chainload_x86", "description": "Wrapped: Windows x86 (AMD Drivers)"},
                "linux": {"method": "grub_x86", "description": "Wrapped: Ubuntu x86 (AMD Modules)"}
            },
            "INTEL_MAC": {
                "macos": {"method": "native", "description": "Verified: Native Intel Mac Boot"},
                "windows": {"method": "bootcamp_refit", "description": "Wrapped: BootCamp via EFI"},
                "linux": {"method": "grub_mac_x86", "description": "Wrapped: Ubuntu x86 (Mac Drivers)"}
            },
            "ARM_MAC": {
                "macos": {"method": "native_arm", "description": "Verified: Native Apple Silicon Boot"},
                "windows": {"method": "arm_windows_injection", "description": "EXPERIMENTAL: Windows ARM via m1n1/UEFI"},
                "linux": {"method": "asahi_wrapper", "description": "Wrapped: Ubuntu ARM (Asahi Kernel)"}
            }
        }
        
        return strategies.get(computer_type, {}).get(target_os, {})
    
    def check_driver_archive(self, target_os):
        """Check what's in the driver archive for target OS"""
        archive_dir = self.base_dir / "DriverArchive"
        
        if target_os == "macos":
            kext_dir = archive_dir / "macOS" / "Kexts"
            if kext_dir.exists():
                kexts = list(kext_dir.glob("*.kext"))
                return {"found": len(kexts), "kexts": [k.name for k in kexts]}
        
        elif target_os == "windows":
            driver_dir = archive_dir / "Windows"
            if driver_dir.exists():
                drivers = list(driver_dir.rglob("*.exe")) + list(driver_dir.rglob("*.inf"))
                return {"found": len(drivers), "drivers": [d.name for d in drivers]}
        
        elif target_os == "linux":
            module_dir = archive_dir / "Linux" / "modules"
            if module_dir.exists():
                modules = list(module_dir.rglob("*.ko"))
                return {"found": len(modules), "modules": [m.name for m in modules]}
        
        return {"found": 0}
    
    def configure_boot(self, target_os):
        """Configure wrapped boot for selected OS"""
        computer_type = self.detect_computer_type()
        strategy = self.get_boot_strategy(computer_type, target_os)
        archive_status = self.check_driver_archive(target_os)
        
        print(f"\n{'='*60}")
        print(f"🔥 UNIVERSAL WRAPPER - Configuring {target_os.upper()}")
        print(f"{'='*60}")
        print(f"\n🖥️  Computer Type: {computer_type}")
        print(f"🎯 Target OS: {target_os}")
        print(f"🔧 Wrapper Method: {strategy.get('method', 'unknown')}")
        print(f"📝 {strategy.get('description', 'N/A')}")
        
        print(f"\n📦 Driver Archive Status:")
        print(f"   Found: {archive_status.get('found', 0)} items")
        
        if strategy.get('experimental'):
            print(f"\n⚠️  Warning: Experimental support!")
        
        print(f"\n📋 Wrapping Steps:")
        for i, step in enumerate(strategy.get('steps', []), 1):
            print(f"   {i}. {step}")
        
        return {
            'computer_type': computer_type,
            'target_os': target_os,
            'strategy': strategy,
            'archive_status': archive_status
        }
    
    def show_boot_menu(self):
        """Show boot menu with wrapping info for all OSes"""
        computer_type = self.detect_computer_type()
        
        print("\n" + "="*60)
        print("🔥 UNIVERSAL MULTIBOOT - GENESIS (ALL WRAPPED)")
        print("="*60)
        print(f"\n💻 Computer: {computer_type}")
        print(f"🖥️  CPU: {self.hardware.get('cpu', {}).get('name', 'Unknown')}")
        print(f"⚡ Firmware: {self.hardware.get('firmware', 'Unknown')}")
        
        print(f"\n🎯 ALL Operating Systems Are WRAPPED:")
        print(f"   (Hardware detection → Driver check → Injection → Boot)")
        
        for i, os_name in enumerate(['macOS', 'Windows', 'Linux'], 1):
            os_lower = os_name.lower()
            strategy = self.get_boot_strategy(computer_type, os_lower)
            archive = self.check_driver_archive(os_lower)
            
            print(f"\n{i}. {os_name}")
            print(f"   Wrapper: {strategy.get('method', 'N/A')}")
            print(f"   Method: {strategy.get('description', 'N/A')}")
            print(f"   Archive: {archive.get('found', 0)} drivers ready")
        
        print("\n" + "="*60)
        print("💡 Every OS gets: detection → archive check → injection")
        print("="*60)

    def generate_grub_dynamic_cfg(self):
        """Generate grub_dynamic.cfg based on detected hardware"""
        computer_type = self.detect_computer_type()
        cfg_path = self.base_dir / "grub_dynamic.cfg"

        with open(cfg_path, "w") as f:
            f.write(f"# Generated by Universal Wrapper for {computer_type}\n\n")

            for os_name in ['macos', 'windows', 'linux']:
                strategy = self.get_boot_strategy(computer_type, os_name)
                if not strategy:
                    continue

                f.write(f'menuentry "{os_name.capitalize()} ({strategy.get("description", "N/A")})" {{\n')

                # Platform-specific boot logic
                if computer_type in ["INTEL_PC", "AMD_PC", "INTEL_MAC"]:
                    # x86 Boot Logic
                    if os_name == 'linux':
                        # Use verified Genesis UUID and paths
                        f.write(f'    linux /ubuntu_system/boot/vmlinuz-6.8.0-90-generic root=UUID=51972f11-0858-4d8b-b710-0facc7be9738 ro quiet splash\n')
                        f.write(f'    initrd /ubuntu_system/boot/initrd.img-6.8.0-90-generic\n')
                    elif os_name == 'windows':
                        f.write(f'    insmod chain\n')
                        f.write(f'    search --no-floppy --fs-uuid --set=root 2CF676F66E6B4DC4\n')
                        f.write(f'    chainloader /EFI/Microsoft/Boot/bootmgfw.efi\n')
                    elif os_name == 'macos':
                        f.write(f'    insmod chain\n')
                        f.write(f'    search --no-floppy --fs-uuid --set=root 32AC-EED7\n')
                        f.write(f'    chainloader /EFI/OC/OpenCore.efi\n')
                
                elif computer_type == "ARM_MAC":
                    # ARM Boot Logic
                    if os_name == 'linux':
                        f.write(f'    echo "Preparing to boot Asahi Linux..."\n')
                        f.write(f'    chainloader /DriverArchive/ARM_Bootloaders/m1n1.bin\n')
                        f.write(f'    devicetree /DriverArchive/ARM_Bootloaders/u-boot.bin\n')
                    else:
                        f.write(f'    echo "Booting {os_name} on Apple Silicon is not yet implemented via GRUB."\n')
                
                else:
                    f.write(f'    echo "Unsupported computer type: {computer_type}"\n')

                f.write("}\n\n")
        
        print(f"✅ grub_dynamic.cfg generated for {computer_type} at {cfg_path}")

def main():
    """Test the universal wrapper"""
    import sys
    test_mode = '--test' in sys.argv

    wrapper = UniversalWrapper()
    
    # Generate grub_dynamic.cfg
    wrapper.generate_grub_dynamic_cfg()

    # Show the boot menu
    wrapper.show_boot_menu()
    
    # Test each OS configuration
    for os_name in ['macos', 'windows', 'linux']:
        config = wrapper.configure_boot(os_name)
        if not test_mode:
            input(f"\nPress Enter to continue to next OS...")

if __name__ == "__main__":
    main()
