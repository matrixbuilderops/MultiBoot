#!/usr/bin/env python3
"""
Universal MultiBot Manager
Main orchestration script for the Universal OS Wrapper
"""

import json
import sys
import subprocess
from pathlib import Path
import argparse

class UniversalMultiBootManager:
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.boot_scripts_dir = self.base_dir / "BootScripts"
        self.hardware_profiles_dir = self.base_dir / "HardwareProfiles"
        self.driver_archive_dir = self.base_dir / "DriverArchive"
        
    def detect_hardware(self):
        """Run hardware detection"""
        print("=" * 60)
        print("STEP 1: Hardware Detection")
        print("=" * 60)
        
        script = self.boot_scripts_dir / "detect_hardware.py"
        result = subprocess.run([sys.executable, str(script)])
        
        if result.returncode != 0:
            print("❌ Hardware detection failed!")
            return False
        
        return True
    
    def map_drivers(self):
        """Run driver mapping"""
        print("\n" + "=" * 60)
        print("STEP 2: Driver Mapping")
        print("=" * 60)
        
        script = self.boot_scripts_dir / "driver_mapper.py"
        result = subprocess.run([sys.executable, str(script)])
        
        if result.returncode != 0:
            print("❌ Driver mapping failed!")
            return False
        
        return True
    
    def build_kext_archive(self):
        """Build kext archive"""
        print("\n" + "=" * 60)
        print("STEP 3: Building Kext Archive")
        print("=" * 60)
        
        script = self.boot_scripts_dir / "build_driver_archive.py"
        result = subprocess.run([sys.executable, str(script)])
        
        if result.returncode != 0:
            print("❌ Kext archive build failed!")
            return False
        
        return True
    
    def generate_efi(self, target_os="all"):
        """Generate EFI configuration for target OS"""
        print("\n" + "=" * 60)
        print(f"STEP 4: Generating EFI for {target_os.upper()}")
        print("=" * 60)
        
        # Load hardware profile
        profile_path = self.hardware_profiles_dir / "current.json"
        manifest_path = self.hardware_profiles_dir / "current_manifest.json"
        
        if not profile_path.exists():
            print("❌ No hardware profile found! Run detection first.")
            return False
        
        with open(profile_path, 'r') as f:
            hardware = json.load(f)
        
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
        
        if target_os == "macos" or target_os == "all":
            print("\n📱 macOS Configuration:")
            print(f"  Platform: {hardware['platform']}")
            print(f"  Firmware: {hardware['firmware']}")
            print(f"  Required Kexts: {len(manifest['macos']['kexts'])}")
            for kext in manifest['macos']['kexts']:
                print(f"    - {kext}")
        
        if target_os == "windows" or target_os == "all":
            print("\n🪟 Windows Configuration:")
            print(f"  Platform: {hardware['platform']}")
            print(f"  Firmware: {hardware['firmware']}")
            print(f"  Required Drivers: {len(manifest['windows']['drivers'])}")
            for driver in manifest['windows']['drivers']:
                print(f"    - {driver}")
        
        if target_os == "linux" or target_os == "all":
            print("\n🐧 Linux Configuration:")
            print(f"  Platform: {hardware['platform']}")
            print(f"  Firmware: {hardware['firmware']}")
            print(f"  Required Modules: {len(manifest['linux']['modules'])}")
            for module in manifest['linux']['modules']:
                print(f"    - {module}")
        
        return True
    
    def check_drive_space(self):
        """Check available space on 2TB drive"""
        print("\n" + "=" * 60)
        print("Drive Space Analysis")
        print("=" * 60)
        
        try:
            result = subprocess.run(
                ["df", "-h", "/dev/sdd1", "/dev/sdd2", "/dev/sdd3", "/dev/sdd4"],
                capture_output=True,
                text=True
            )
            print(result.stdout)
        except Exception as e:
            print(f"Could not check drive space: {e}")
    
    def show_status(self):
        """Show current status"""
        print("\n" + "=" * 60)
        print("Universal MultiBoot System Status")
        print("=" * 60)
        
        # Check for hardware profile
        profile_exists = (self.hardware_profiles_dir / "current.json").exists()
        manifest_exists = (self.hardware_profiles_dir / "current_manifest.json").exists()
        
        print(f"\n✅ Hardware Profile: {'Found' if profile_exists else 'Not Found'}")
        print(f"✅ Driver Manifest: {'Found' if manifest_exists else 'Not Found'}")
        
        # Check kext archive
        kext_archive_dir = self.driver_archive_dir / "macOS" / "Kexts"
        if kext_archive_dir.exists():
            kext_count = len(list(kext_archive_dir.iterdir()))
            print(f"✅ Kext Archive: {kext_count} kexts downloaded")
        else:
            print("❌ Kext Archive: Not built")
        
        # Check OpCore engine
        opcore_exists = (self.base_dir / "OpCoreEngine" / "OpCore-Simplify.py").exists()
        print(f"✅ OpCore Engine: {'Ready' if opcore_exists else 'Not Found'}")
        
        if profile_exists:
            with open(self.hardware_profiles_dir / "current.json", 'r') as f:
                hardware = json.load(f)
            
            print("\n📊 Detected Hardware:")
            print(f"  CPU: {hardware['cpu'].get('name', 'Unknown')}")
            print(f"  Platform: {hardware.get('platform', 'Unknown')}")
            print(f"  Firmware: {hardware.get('firmware', 'Unknown')}")
            print(f"  GPUs: {len(hardware.get('gpu', []))}")
            print(f"  Network Devices: {len(hardware.get('network', []))}")
    
    def full_setup(self):
        """Run complete setup process"""
        print("🚀 Starting Universal MultiBoot Full Setup...\n")
        
        steps = [
            ("Hardware Detection", self.detect_hardware),
            ("Driver Mapping", self.map_drivers),
            ("Kext Archive Build", self.build_kext_archive),
            ("EFI Generation", lambda: self.generate_efi("all"))
        ]
        
        for step_name, step_func in steps:
            if not step_func():
                print(f"\n❌ Setup failed at: {step_name}")
                return False
        
        print("\n" + "=" * 60)
        print("✅ Universal MultiBoot Setup Complete!")
        print("=" * 60)
        
        self.show_status()
        
        return True

def main():
    parser = argparse.ArgumentParser(
        description="Universal MultiBoot Manager - Manage multiboot drive with macOS/Windows/Linux"
    )
    
    parser.add_argument(
        "action",
        choices=["detect", "map", "build-kexts", "generate-efi", "status", "full-setup"],
        help="Action to perform"
    )
    
    parser.add_argument(
        "--os",
        choices=["macos", "windows", "linux", "all"],
        default="all",
        help="Target OS for EFI generation"
    )
    
    args = parser.parse_args()
    
    manager = UniversalMultiBootManager()
    
    if args.action == "detect":
        manager.detect_hardware()
    elif args.action == "map":
        manager.map_drivers()
    elif args.action == "build-kexts":
        manager.build_kext_archive()
    elif args.action == "generate-efi":
        manager.generate_efi(args.os)
    elif args.action == "status":
        manager.show_status()
    elif args.action == "full-setup":
        manager.full_setup()

if __name__ == "__main__":
    main()
