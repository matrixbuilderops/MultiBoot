#!/usr/bin/env python3
"""
Driver Archive Builder
Downloads essential drivers/kexts/modules to local archive
"""

import subprocess
import json
from pathlib import Path
import urllib.request
import shutil

class DriverArchiveBuilder:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.archive_dir = self.base_dir / "DriverArchive"
        
        # Kext sources (GitHub releases)
        self.kext_sources = {
            'Lilu.kext': 'https://github.com/acidanthera/Lilu/releases/latest/download/Lilu-Release.zip',
            'VirtualSMC.kext': 'https://github.com/acidanthera/VirtualSMC/releases/latest/download/VirtualSMC-Release.zip',
            'WhateverGreen.kext': 'https://github.com/acidanthera/WhateverGreen/releases/latest/download/WhateverGreen-Release.zip',
            'AppleALC.kext': 'https://github.com/acidanthera/AppleALC/releases/latest/download/AppleALC-Release.zip',
            'AirportItlwm.kext': 'https://github.com/OpenIntelWireless/itlwm/releases/latest/download/AirportItlwm_v2.3.0_stable_Sonoma.kext.zip',
            'IntelMausi.kext': 'https://github.com/acidanthera/IntelMausi/releases/latest/download/IntelMausi-Release.zip',
            'RealtekRTL8111.kext': 'https://github.com/Mieze/RTL8111_driver_for_OS_X/releases/latest/download/RealtekRTL8111-V2.4.2.zip',
            'USBInjectAll.kext': 'https://bitbucket.org/RehabMan/os-x-usb-inject-all/downloads/RehabMan-USBInjectAll-2018-1108.zip',
            'IntelBluetoothFirmware.kext': 'https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases/latest/download/IntelBluetoothFirmware-v2.4.0.zip',
            'BrcmPatchRAM3.kext': 'https://github.com/acidanthera/BrcmPatchRAM/releases/latest/download/BrcmPatchRAM-Release.zip',
            'NootedRed.kext': 'https://github.com/ChefKissInc/NootedRed/releases/latest/download/NootedRed.zip'
        }
    
    def check_internet(self):
        """Check if internet is available"""
        try:
            urllib.request.urlopen('https://www.google.com', timeout=3)
            return True
        except:
            return False
    
    def download_file(self, url, destination):
        """Download file with progress"""
        try:
            print(f"   Downloading from: {url}")
            urllib.request.urlretrieve(url, destination)
            return True
        except Exception as e:
            print(f"   ❌ Failed: {e}")
            return False
    
    def extract_kext(self, zip_file, kext_name):
        """Extract kext from zip file"""
        try:
            kext_dir = self.archive_dir / "macOS" / "Kexts"
            kext_dir.mkdir(parents=True, exist_ok=True)
            
            # Use unzip command
            result = subprocess.run(
                ['unzip', '-q', '-o', str(zip_file), '-d', str(kext_dir)],
                capture_output=True
            )
            
            # Find the extracted .kext
            extracted_kexts = list(kext_dir.rglob(f"{kext_name}"))
            if extracted_kexts:
                print(f"   ✅ Extracted: {kext_name}")
                return True
            else:
                print(f"   ⚠️  Kext found but might need manual extraction")
                return False
        except Exception as e:
            print(f"   ❌ Extract failed: {e}")
            return False
    
    def build_macos_archive(self):
        """Download macOS kexts"""
        print("\n" + "="*60)
        print("🍎 Building macOS Kext Archive")
        print("="*60)
        
        # Load manifest to see what's needed
        manifest_file = self.base_dir / "HardwareProfiles" / "current_manifest.json"
        needed_kexts = []
        
        if manifest_file.exists():
            with open(manifest_file, 'r') as f:
                manifest = json.load(f)
                needed_kexts = manifest.get('macos', {}).get('kexts', [])
        
        print(f"\n📋 Required kexts: {len(needed_kexts)}")
        for kext in needed_kexts:
            print(f"   - {kext}")
        
        # Check what's already in archive
        kext_dir = self.archive_dir / "macOS" / "Kexts"
        kext_dir.mkdir(parents=True, exist_ok=True)
        
        existing = list(kext_dir.glob("*.kext"))
        print(f"\n📦 Already in archive: {len(existing)}")
        
        # Download missing kexts
        print(f"\n⬇️  Downloading kexts...")
        
        if not self.check_internet():
            print("   ❌ No internet connection!")
            print("   ⚠️  Will use existing archive only")
            return False
        
        download_count = 0
        for kext_name, url in self.kext_sources.items():
            print(f"\n📥 {kext_name}")
            
            # Check if already exists
            if any(kext_name in str(k) for k in existing):
                print(f"   ✅ Already in archive, skipping")
                continue
            
            # Download to temp
            temp_zip = Path(f"/tmp/{kext_name}.zip")
            if self.download_file(url, temp_zip):
                if self.extract_kext(temp_zip, kext_name):
                    download_count += 1
                temp_zip.unlink(missing_ok=True)
        
        print(f"\n✅ Downloaded {download_count} new kexts")
        
        # Show final count
        final_kexts = list(kext_dir.glob("*.kext"))
        print(f"📦 Total in archive: {len(final_kexts)} kexts")
        
        return True
    
    def build_windows_archive(self):
        """Setup Windows driver structure"""
        print("\n" + "="*60)
        print("🪟 Building Windows Driver Archive")
        print("="*60)
        
        # Create directory structure
        dirs = [
            "Windows/Network",
            "Windows/Graphics", 
            "Windows/Storage",
            "Windows/Chipset"
        ]
        
        for dir_path in dirs:
            (self.archive_dir / dir_path).mkdir(parents=True, exist_ok=True)
        
        print("\n📁 Created directory structure:")
        for dir_path in dirs:
            print(f"   - {dir_path}/")
        
        print("\n⚠️  Windows drivers need to be downloaded manually:")
        print("   1. Intel WiFi: https://www.intel.com/content/www/us/en/download/19351")
        print("   2. Intel Ethernet: https://www.intel.com/content/www/us/en/download/15084")
        print("   3. NVIDIA: https://www.nvidia.com/Download/index.aspx")
        print("   4. AMD: https://www.amd.com/en/support")
        print("   5. Intel Chipset: https://www.intel.com/content/www/us/en/download/19347")
        
        print("\n💡 Place downloaded drivers in DriverArchive/Windows/")
        
        return True
    
    def build_linux_archive(self):
        """Setup Linux module structure"""
        print("\n" + "="*60)
        print("🐧 Building Linux Module Archive")
        print("="*60)
        
        # Create directory structure
        dirs = [
            "Linux/modules/x86_64",
            "Linux/modules/arm64",
            "Linux/firmware"
        ]
        
        for dir_path in dirs:
            (self.archive_dir / dir_path).mkdir(parents=True, exist_ok=True)
        
        print("\n📁 Created directory structure:")
        for dir_path in dirs:
            print(f"   - {dir_path}/")
        
        print("\n💡 Linux modules will be copied from system at boot time")
        print("   Most modules already exist in /lib/modules/")
        
        return True
    
    def show_archive_status(self):
        """Show current archive status"""
        print("\n" + "="*60)
        print("📊 Driver Archive Status")
        print("="*60)
        
        # macOS kexts
        kext_dir = self.archive_dir / "macOS" / "Kexts"
        if kext_dir.exists():
            kexts = list(kext_dir.glob("*.kext"))
            print(f"\n🍎 macOS: {len(kexts)} kexts")
            for kext in kexts[:10]:  # Show first 10
                print(f"   ✅ {kext.name}")
            if len(kexts) > 10:
                print(f"   ... and {len(kexts)-10} more")
        
        # Windows drivers
        win_dir = self.archive_dir / "Windows"
        if win_dir.exists():
            drivers = list(win_dir.rglob("*.exe")) + list(win_dir.rglob("*.inf"))
            print(f"\n🪟 Windows: {len(drivers)} drivers")
            if drivers:
                for driver in drivers[:5]:
                    print(f"   ✅ {driver.name}")
            else:
                print("   ⚠️  No drivers yet (manual download required)")
        
        # Linux modules
        linux_dir = self.archive_dir / "Linux"
        if linux_dir.exists():
            modules = list(linux_dir.rglob("*.ko"))
            print(f"\n🐧 Linux: {len(modules)} modules")
            if not modules:
                print("   💡 Will be populated from system at boot")
        
        # Calculate total size
        total_size = sum(f.stat().st_size for f in self.archive_dir.rglob('*') if f.is_file())
        size_mb = total_size / 1024 / 1024
        
        print(f"\n💾 Total Archive Size: {size_mb:.1f} MB")

def main():
    """Build the driver archive"""
    builder = DriverArchiveBuilder()
    
    print("🔥 UNIVERSAL MULTIBOOT - Driver Archive Builder")
    
    # Build each archive
    builder.build_macos_archive()
    builder.build_windows_archive()
    builder.build_linux_archive()
    
    # Show status
    builder.show_archive_status()
    
    print("\n" + "="*60)
    print("✅ Driver Archive Build Complete!")
    print("="*60)
    print("\nNext steps:")
    print("1. Download Windows drivers manually")
    print("2. Build injection scripts")
    print("3. Install to 2TB drive")

if __name__ == "__main__":
    main()
