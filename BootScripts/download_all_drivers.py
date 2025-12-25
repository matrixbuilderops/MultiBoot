#!/usr/bin/env python3
"""
Download ALL drivers for comprehensive archive
- macOS kexts
- Windows drivers  
- Linux modules
- Asahi drivers
"""

import urllib.request
import subprocess
import shutil
from pathlib import Path
import json
import tarfile
import zipfile

class DriverDownloader:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.archive_dir = self.base_dir / "DriverArchive"
        
        # Direct download URLs for kexts
        self.kext_urls = {
            'Lilu': 'https://github.com/acidanthera/Lilu/releases/download/1.6.8/Lilu-1.6.8-RELEASE.zip',
            'VirtualSMC': 'https://github.com/acidanthera/VirtualSMC/releases/download/1.3.3/VirtualSMC-1.3.3-RELEASE.zip',
            'WhateverGreen': 'https://github.com/acidanthera/WhateverGreen/releases/download/1.6.7/WhateverGreen-1.6.7-RELEASE.zip',
            'AppleALC': 'https://github.com/acidanthera/AppleALC/releases/download/1.9.1/AppleALC-1.9.1-RELEASE.zip',
            'IntelMausi': 'https://github.com/acidanthera/IntelMausi/releases/download/1.0.8/IntelMausi-1.0.8-RELEASE.zip',
            'RealtekRTL8111': 'https://github.com/Mieze/RTL8111_driver_for_OS_X/releases/download/v2.4.2/RealtekRTL8111-V2.4.2.zip',
            'AirportItlwm-Sonoma': 'https://github.com/OpenIntelWireless/itlwm/releases/download/v2.3.0/AirportItlwm_v2.3.0_stable_Sonoma.kext.zip',
            'IntelBluetoothFirmware': 'https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases/download/v2.4.0/IntelBluetoothFirmware-v2.4.0.zip',
            'BrcmPatchRAM': 'https://github.com/acidanthera/BrcmPatchRAM/releases/download/2.6.9/BrcmPatchRAM-2.6.9-RELEASE.zip',
            'NootedRed': 'https://github.com/ChefKissInc/NootedRed/releases/download/1.5.3/NootedRed-1.5.3-RELEASE.zip',
        }
    
    def download_file(self, url, dest):
        """Download file with progress"""
        try:
            print(f"   Downloading: {dest.name}")
            urllib.request.urlretrieve(url, dest)
            return True
        except Exception as e:
            print(f"   ❌ Failed: {e}")
            return False
    
    def extract_kext_from_zip(self, zip_file, dest_dir):
        """Extract kext from zip"""
        try:
            with zipfile.ZipFile(zip_file, 'r') as zf:
                # Find .kext directories
                kext_files = [f for f in zf.namelist() if '.kext/' in f]
                if kext_files:
                    zf.extractall(dest_dir)
                    return True
            return False
        except Exception as e:
            print(f"   ⚠️  Extract error: {e}")
            return False
    
    def download_macos_kexts(self):
        """Download all macOS kexts"""
        print("\n" + "="*60)
        print("🍎 Downloading macOS Kexts")
        print("="*60)
        
        universal_dir = self.archive_dir / "macOS" / "Universal"
        pc_specific_dir = self.archive_dir / "macOS" / "PC_Specific"
        universal_dir.mkdir(parents=True, exist_ok=True)
        pc_specific_dir.mkdir(parents=True, exist_ok=True)
        
        downloaded = 0
        for name, url in self.kext_urls.items():
            print(f"\n📥 {name}")
            
            zip_file = Path(f"/tmp/{name}.zip")
            if self.download_file(url, zip_file):
                # Extract to PC_Specific (hackintosh kexts)
                if self.extract_kext_from_zip(zip_file, pc_specific_dir):
                    print(f"   ✅ Extracted to PC_Specific")
                    downloaded += 1
                
                # Some are also universal
                if name in ['Lilu', 'VirtualSMC', 'AppleALC']:
                    self.extract_kext_from_zip(zip_file, universal_dir)
                
                zip_file.unlink()
        
        print(f"\n✅ Downloaded {downloaded}/{len(self.kext_urls)} kexts")
        return downloaded
    
    def copy_linux_modules(self):
        """Copy Linux modules from system"""
        print("\n" + "="*60)
        print("🐧 Copying Linux Modules")
        print("="*60)
        
        linux_dir = self.archive_dir / "Linux" / "x86_Common"
        linux_dir.mkdir(parents=True, exist_ok=True)
        
        # Modules to copy
        modules = ['e1000e', 'i915', 'iwlwifi', 'iwlmvm', 'r8169', 
                   'nvidia', 'nouveau', 'amdgpu']
        
        system_modules = Path("/lib/modules")
        if not system_modules.exists():
            print("❌ /lib/modules not found")
            return 0
        
        copied = 0
        for module in modules:
            matches = list(system_modules.rglob(f"{module}.ko*"))
            if matches:
                dest = linux_dir / matches[0].name
                shutil.copy2(matches[0], dest)
                print(f"   ✅ {module}.ko")
                copied += 1
        
        print(f"\n✅ Copied {copied} modules")
        return copied
    
    def extract_asahi_drivers(self):
        """Extract Asahi Linux drivers from repos archive"""
        print("\n" + "="*60)
        print("🍎 Extracting Asahi Linux Drivers (ARM)")
        print("="*60)
        
        repos_archive = self.base_dir / "multiboot-repos.tar.gz"
        if not repos_archive.exists():
            print("❌ multiboot-repos.tar.gz not found")
            return 0
        
        asahi_dir = self.archive_dir / "Linux" / "Asahi"
        asahi_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"\n📦 Extracting from {repos_archive.name} (85MB)...")
        print("   This may take a few minutes...")
        
        try:
            with tarfile.open(repos_archive, 'r:gz') as tar:
                # Extract everything
                tar.extractall(self.base_dir / "AsahiRepos")
            
            print("✅ Asahi repos extracted")
            
            # Look for driver files
            asahi_repos = self.base_dir / "AsahiRepos"
            if asahi_repos.exists():
                driver_files = list(asahi_repos.rglob("*.ko"))
                print(f"   Found {len(driver_files)} kernel modules")
                
                # Copy a few key ones
                for driver in driver_files[:20]:
                    dest = asahi_dir / driver.name
                    shutil.copy2(driver, dest)
                
                return len(driver_files)
        except Exception as e:
            print(f"❌ Error: {e}")
            return 0
    
    def show_windows_instructions(self):
        """Show where to download Windows drivers"""
        print("\n" + "="*60)
        print("🪟 Windows Drivers (Manual Download Required)")
        print("="*60)
        
        print("\nWindows drivers need manual download:")
        print("\n📥 Intel Drivers:")
        print("   WiFi/BT: https://www.intel.com/content/www/us/en/download/19351/intel-wireless-bluetooth-for-windows-10-and-windows-11.html")
        print("   Ethernet: https://www.intel.com/content/www/us/en/download/15084/intel-network-adapter-driver-for-windows-10.html")
        print("   Graphics: https://www.intel.com/content/www/us/en/download/785597/intel-arc-iris-xe-graphics-windows.html")
        print("   Chipset: https://www.intel.com/content/www/us/en/download/19347/intel-chipset-device-software-for-windows-10-and-windows-11.html")
        
        print("\n📥 GPU Drivers:")
        print("   NVIDIA: https://www.nvidia.com/Download/index.aspx")
        print("   AMD: https://www.amd.com/en/support")
        
        print("\n📥 Boot Camp (Windows on Mac):")
        print("   Download Boot Camp Support Software from:")
        print("   https://support.apple.com/en-us/102384")
        
        print(f"\n💾 Save drivers to:")
        print(f"   {self.archive_dir / 'Windows' / 'PC_Drivers'}")
        print(f"   {self.archive_dir / 'Windows' / 'BootCamp_Drivers'}")
    
    def download_all(self):
        """Download everything"""
        print("="*60)
        print("  🔥 UNIVERSAL DRIVER DOWNLOADER")
        print("="*60)
        
        totals = {}
        
        # macOS kexts
        totals['kexts'] = self.download_macos_kexts()
        
        # Linux modules
        totals['linux'] = self.copy_linux_modules()
        
        # Asahi drivers
        totals['asahi'] = self.extract_asahi_drivers()
        
        # Windows (manual)
        self.show_windows_instructions()
        
        # Summary
        print("\n" + "="*60)
        print("  📊 DOWNLOAD SUMMARY")
        print("="*60)
        print(f"\n✅ macOS Kexts: {totals['kexts']} downloaded")
        print(f"✅ Linux Modules: {totals['linux']} copied")
        print(f"✅ Asahi Drivers: {totals['asahi']} extracted")
        print(f"⚠️  Windows Drivers: Manual download required")
        
        # Show archive size
        archive_size = sum(f.stat().st_size for f in self.archive_dir.rglob('*') if f.is_file())
        size_mb = archive_size / 1024 / 1024
        print(f"\n💾 Archive Size: {size_mb:.1f} MB")
        
        print("\n" + "="*60)
        print("  ✅ DOWNLOAD COMPLETE!")
        print("="*60)

if __name__ == "__main__":
    downloader = DriverDownloader()
    downloader.download_all()
