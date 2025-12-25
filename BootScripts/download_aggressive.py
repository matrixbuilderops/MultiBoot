#!/usr/bin/env python3
"""
AGGRESSIVE DRIVER DOWNLOADER - Download EVERYTHING
No excuses, no failures!
"""

import urllib.request
import subprocess
import shutil
from pathlib import Path
import zipfile
import tarfile
import time

class AggressiveDownloader:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.archive_dir = self.base_dir / "DriverArchive"
        self.downloaded = 0
        self.failed = 0
        
        # ALL macOS kexts - comprehensive list
        self.kext_urls = {
            # Core (ESSENTIAL)
            'Lilu': 'https://github.com/acidanthera/Lilu/releases/download/1.6.8/Lilu-1.6.8-RELEASE.zip',
            'VirtualSMC': 'https://github.com/acidanthera/VirtualSMC/releases/download/1.3.3/VirtualSMC-1.3.3-RELEASE.zip',
            
            # Graphics
            'WhateverGreen': 'https://github.com/acidanthera/WhateverGreen/releases/download/1.6.7/WhateverGreen-1.6.7-RELEASE.zip',
            'NootedRed': 'https://github.com/ChefKissInc/NootedRed/releases/download/1.5.3/NootedRed-1.5.3-RELEASE.zip',
            
            # Audio
            'AppleALC': 'https://github.com/acidanthera/AppleALC/releases/download/1.9.1/AppleALC-1.9.1-RELEASE.zip',
            
            # Network - Intel
            'IntelMausi': 'https://github.com/acidanthera/IntelMausi/releases/download/1.0.8/IntelMausi-1.0.8-RELEASE.zip',
            'AirportItlwm-Sonoma': 'https://github.com/OpenIntelWireless/itlwm/releases/download/v2.3.0/AirportItlwm_v2.3.0_stable_Sonoma.kext.zip',
            'AirportItlwm-Ventura': 'https://github.com/OpenIntelWireless/itlwm/releases/download/v2.3.0/AirportItlwm_v2.3.0_stable_Ventura.kext.zip',
            'IntelBluetoothFirmware': 'https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases/download/v2.4.0/IntelBluetoothFirmware-v2.4.0.zip',
            
            # Network - Realtek
            'RealtekRTL8111': 'https://github.com/Mieze/RTL8111_driver_for_OS_X/releases/download/v2.4.2/RealtekRTL8111-V2.4.2.zip',
            'RealtekRTL8125': 'https://github.com/Mieze/LucyRTL8125Ethernet/releases/download/1.1.0/LucyRTL8125Ethernet-V1.1.0.zip',
            
            # Network - Broadcom
            'BrcmPatchRAM': 'https://github.com/acidanthera/BrcmPatchRAM/releases/download/2.6.9/BrcmPatchRAM-2.6.9-RELEASE.zip',
            
            # USB
            'USBToolBox': 'https://github.com/USBToolBox/kext/releases/download/1.1.1/USBToolBox-1.1.1-RELEASE.zip',
            
            # CPU Power Management
            'CPUFriend': 'https://github.com/acidanthera/CPUFriend/releases/download/1.2.8/CPUFriend-1.2.8-RELEASE.zip',
            'AMDRyzenCPUPowerManagement': 'https://github.com/trulyspinach/SMCAMDProcessor/releases/download/0.7.1/AMDRyzenCPUPowerManagement-0.7.1-RELEASE.zip',
            
            # Sensors
            'SMCAMDProcessor': 'https://github.com/trulyspinach/SMCAMDProcessor/releases/download/0.7.1/SMCAMDProcessor-0.7.1-RELEASE.zip',
            
            # Other
            'NVMeFix': 'https://github.com/acidanthera/NVMeFix/releases/download/1.1.1/NVMeFix-1.1.1-RELEASE.zip',
            'RestrictEvents': 'https://github.com/acidanthera/RestrictEvents/releases/download/1.1.4/RestrictEvents-1.1.4-RELEASE.zip',
        }
    
    def download_with_retry(self, url, dest, retries=3):
        """Download with retries"""
        for attempt in range(retries):
            try:
                print(f"   Attempt {attempt+1}/{retries}...", end=" ")
                urllib.request.urlretrieve(url, dest)
                print("✅")
                return True
            except Exception as e:
                print(f"❌ {e}")
                time.sleep(2)
        return False
    
    def extract_all_kexts(self, zip_file, dest_dir):
        """Extract ALL kexts from zip"""
        extracted = []
        try:
            with zipfile.ZipFile(zip_file, 'r') as zf:
                for member in zf.namelist():
                    if member.endswith('.kext/') or '.kext/' in member:
                        zf.extract(member, dest_dir)
                        if member.endswith('.kext/'):
                            extracted.append(member)
            return len(extracted) > 0
        except Exception as e:
            print(f"   Extract error: {e}")
            return False
    
    def download_all_kexts(self):
        """Download ALL kexts aggressively"""
        print("\n" + "="*60)
        print("🍎 DOWNLOADING ALL KEXTS (AGGRESSIVE MODE)")
        print("="*60)
        
        universal_dir = self.archive_dir / "macOS" / "Universal"
        pc_dir = self.archive_dir / "macOS" / "PC_Specific"
        universal_dir.mkdir(parents=True, exist_ok=True)
        pc_dir.mkdir(parents=True, exist_ok=True)
        
        for name, url in self.kext_urls.items():
            print(f"\n📥 {name}")
            
            zip_file = Path(f"/tmp/{name}.zip")
            if self.download_with_retry(url, zip_file):
                if self.extract_all_kexts(zip_file, pc_dir):
                    print(f"   ✅ Extracted")
                    self.downloaded += 1
                    
                    # Universal ones
                    if name in ['Lilu', 'VirtualSMC', 'AppleALC']:
                        self.extract_all_kexts(zip_file, universal_dir)
                else:
                    print(f"   ⚠️  Extraction failed")
                    self.failed += 1
                
                zip_file.unlink()
            else:
                print(f"   ❌ Download failed completely")
                self.failed += 1
        
        print(f"\n✅ Downloaded: {self.downloaded}/{len(self.kext_urls)}")
        if self.failed > 0:
            print(f"❌ Failed: {self.failed}")
    
    def copy_all_linux_modules(self):
        """Copy EVERY useful Linux module"""
        print("\n" + "="*60)
        print("🐧 COPYING ALL LINUX MODULES")
        print("="*60)
        
        linux_dir = self.archive_dir / "Linux" / "x86_Common"
        linux_dir.mkdir(parents=True, exist_ok=True)
        
        # Comprehensive module list
        modules = [
            # Network
            'e1000e', 'igb', 'ixgbe', 'i40e',  # Intel Ethernet
            'r8169', 'r8168',  # Realtek
            'iwlwifi', 'iwlmvm', 'iwldvm',  # Intel WiFi
            'rtw88', 'rtw89',  # Realtek WiFi
            'ath9k', 'ath10k',  # Atheros
            'brcmfmac', 'brcmsmac',  # Broadcom
            # Graphics
            'i915',  # Intel
            'amdgpu', 'radeon',  # AMD
            'nvidia', 'nouveau',  # NVIDIA
            # Sound
            'snd_hda_intel', 'snd_hda_codec_realtek',
            # USB
            'xhci_hcd', 'ehci_hcd',
        ]
        
        system_modules = Path("/lib/modules")
        if not system_modules.exists():
            print("❌ /lib/modules not found")
            return
        
        copied = 0
        for module in modules:
            matches = list(system_modules.rglob(f"{module}.ko*"))
            if matches:
                for match in matches[:1]:  # Take first match
                    dest = linux_dir / match.name
                    try:
                        shutil.copy2(match, dest)
                        print(f"   ✅ {module}")
                        copied += 1
                        break
                    except:
                        pass
        
        print(f"\n✅ Copied: {copied}/{len(modules)} modules")
    
    def extract_asahi_properly(self):
        """Extract Asahi drivers PROPERLY"""
        print("\n" + "="*60)
        print("🍎 EXTRACTING ASAHI LINUX DRIVERS")
        print("="*60)
        
        repos_archive = self.base_dir / "multiboot-repos.tar.gz"
        if not repos_archive.exists():
            print("❌ Archive not found")
            return
        
        asahi_dir = self.archive_dir / "Linux" / "Asahi"
        asahi_dir.mkdir(parents=True, exist_ok=True)
        
        extract_dir = Path("/tmp/asahi_extract")
        if extract_dir.exists():
            shutil.rmtree(extract_dir)
        extract_dir.mkdir()
        
        print(f"\n📦 Extracting 85MB archive...")
        try:
            subprocess.run(['tar', '-xzf', str(repos_archive), '-C', str(extract_dir)], 
                         check=True, capture_output=True, timeout=60)
            
            print("✅ Archive extracted")
            
            # Find ALL driver-related files
            print("\n🔍 Finding Asahi drivers...")
            
            driver_extensions = ['.ko', '.dtb', '.dtbo', '.bin', '.fw']
            found = 0
            
            for ext in driver_extensions:
                files = list(extract_dir.rglob(f"*{ext}"))
                for f in files:
                    try:
                        dest = asahi_dir / f.name
                        shutil.copy2(f, dest)
                        found += 1
                    except:
                        pass
            
            print(f"✅ Copied {found} Asahi driver files")
            
            # Cleanup
            shutil.rmtree(extract_dir)
            
        except subprocess.TimeoutExpired:
            print("⚠️  Extraction taking too long, skipping")
        except Exception as e:
            print(f"❌ Error: {e}")
    
    def download_everything(self):
        """DOWNLOAD EVERYTHING AGGRESSIVELY"""
        print("="*60)
        print("  🔥 AGGRESSIVE DOWNLOAD MODE - NO FAILURES!")
        print("="*60)
        
        self.download_all_kexts()
        self.copy_all_linux_modules()
        self.extract_asahi_properly()
        
        # Summary
        print("\n" + "="*60)
        print("  📊 FINAL SUMMARY")
        print("="*60)
        
        # Count what we actually have
        macos_kexts = len(list((self.archive_dir / "macOS").rglob("*.kext")))
        linux_modules = len(list((self.archive_dir / "Linux").rglob("*.ko*")))
        asahi_files = len(list((self.archive_dir / "Linux" / "Asahi").rglob("*")))
        
        print(f"\n✅ macOS Kexts: {macos_kexts} kexts")
        print(f"✅ Linux Modules: {linux_modules} modules")  
        print(f"✅ Asahi Drivers: {asahi_files} files")
        
        archive_size = sum(f.stat().st_size for f in self.archive_dir.rglob('*') if f.is_file())
        print(f"\n💾 Total Archive: {archive_size/1024/1024:.1f} MB")
        
        print("\n⚠️  Windows drivers still need manual download")
        print("   But we have comprehensive coverage for macOS and Linux!")

if __name__ == "__main__":
    downloader = AggressiveDownloader()
    downloader.download_everything()
