#!/usr/bin/env python3
"""
SMART DRIVER DOWNLOADER
Downloads ANYTHING missing at boot time with internet fallback
"""

import urllib.request
import json
from pathlib import Path
import subprocess
import time

class SmartDownloader:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.archive_dir = self.base_dir / "DriverArchive"
        
        # Comprehensive URL database with multiple fallbacks
        self.driver_sources = {
            # macOS Kexts - Multiple versions for different macOS
            'macos': {
                'Lilu': [
                    'https://github.com/acidanthera/Lilu/releases/download/1.6.8/Lilu-1.6.8-RELEASE.zip',
                    'https://github.com/acidanthera/Lilu/releases/download/1.6.7/Lilu-1.6.7-RELEASE.zip'
                ],
                'VirtualSMC': [
                    'https://github.com/acidanthera/VirtualSMC/releases/download/1.3.3/VirtualSMC-1.3.3-RELEASE.zip',
                ],
                'WhateverGreen': [
                    'https://github.com/acidanthera/WhateverGreen/releases/download/1.6.7/WhateverGreen-1.6.7-RELEASE.zip',
                ],
                'AppleALC': [
                    'https://github.com/acidanthera/AppleALC/releases/download/1.9.1/AppleALC-1.9.1-RELEASE.zip',
                ],
                'NootedRed': [
                    'https://github.com/ChefKissInc/NootedRed/releases/download/1.5.3/NootedRed-1.5.3-RELEASE.zip',
                ],
                'IntelMausi': [
                    'https://github.com/acidanthera/IntelMausi/releases/download/1.0.8/IntelMausi-1.0.8-RELEASE.zip',
                ],
                'AirportItlwm': [
                    'https://github.com/OpenIntelWireless/itlwm/releases/download/v2.3.0/AirportItlwm_v2.3.0_stable_Sonoma.kext.zip',
                    'https://github.com/OpenIntelWireless/itlwm/releases/download/v2.3.0/AirportItlwm_v2.3.0_stable_Ventura.kext.zip',
                ],
                'IntelBluetoothFirmware': [
                    'https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases/download/v2.4.0/IntelBluetoothFirmware-v2.4.0.zip',
                ],
                'RealtekRTL8111': [
                    'https://github.com/Mieze/RTL8111_driver_for_OS_X/releases/download/v2.4.2/RealtekRTL8111-V2.4.2.zip',
                ],
                'BrcmPatchRAM': [
                    'https://github.com/acidanthera/BrcmPatchRAM/releases/download/2.6.9/BrcmPatchRAM-2.6.9-RELEASE.zip',
                ],
                'USBToolBox': [
                    'https://github.com/USBToolBox/kext/releases/download/1.1.1/USBToolBox-1.1.1-RELEASE.zip',
                ],
                'AMDRyzenCPUPowerManagement': [
                    'https://github.com/trulyspinach/SMCAMDProcessor/releases/download/0.7.1/AMDRyzenCPUPowerManagement-0.7.1-RELEASE.zip',
                ],
            },
            
            # Windows drivers with direct/fallback links
            'windows': {
                'Intel_WiFi': [
                    'https://downloadmirror.intel.com/812204/WiFi-23.70.0-Driver64-Win10-Win11.exe',
                    # Fallback: user downloads manually
                ],
                'Intel_Bluetooth': [
                    'https://downloadmirror.intel.com/812204/Intel-Bluetooth-Driver-23.70.0-Win10-Win11.exe',
                ],
                'Intel_Ethernet': [
                    'https://downloadmirror.intel.com/30256/eng/PROWin64.exe',
                ],
            },
            
            # Asahi Linux for ARM Macs
            'asahi': {
                'asahi-linux-kernel': [
                    'https://github.com/AsahiLinux/linux/releases/latest',
                ],
                'asahi-gpu-driver': [
                    'https://github.com/AsahiLinux/gpu/releases/latest',
                ],
            }
        }
    
    def check_internet(self):
        """Check if internet is available"""
        test_urls = [
            'https://www.google.com',
            'https://github.com',
            'https://1.1.1.1'
        ]
        
        for url in test_urls:
            try:
                urllib.request.urlopen(url, timeout=3)
                return True
            except:
                continue
        return False
    
    def download_with_fallback(self, name, urls, dest_file):
        """Try downloading from multiple URLs"""
        for i, url in enumerate(urls):
            try:
                print(f"   Attempt {i+1}/{len(urls)}: {url}")
                urllib.request.urlretrieve(url, dest_file)
                return True
            except Exception as e:
                print(f"   Failed: {e}")
                if i < len(urls) - 1:
                    print(f"   Trying fallback...")
                    time.sleep(1)
        return False
    
    def get_github_latest_release_url(self, repo_url):
        """Get latest release download URL from GitHub"""
        try:
            # Convert repo URL to API URL
            # https://github.com/owner/repo → https://api.github.com/repos/owner/repo/releases/latest
            parts = repo_url.replace('https://github.com/', '').split('/')
            if len(parts) >= 2:
                api_url = f"https://api.github.com/repos/{parts[0]}/{parts[1]}/releases/latest"
                
                req = urllib.request.Request(api_url)
                req.add_header('User-Agent', 'UniversalMultiBoot/1.0')
                
                with urllib.request.urlopen(req, timeout=10) as response:
                    data = json.loads(response.read())
                    
                    # Get first asset download URL
                    if 'assets' in data and len(data['assets']) > 0:
                        return data['assets'][0]['browser_download_url']
        except:
            pass
        return None
    
    def smart_download(self, driver_name, os_type, dest_dir):
        """Smart download with auto-fallback and latest version detection"""
        print(f"\n📥 Downloading {driver_name} for {os_type}...")
        
        # Get URL list
        urls = self.driver_sources.get(os_type, {}).get(driver_name, [])
        
        if not urls:
            print(f"   ❌ No download sources configured")
            return False
        
        # Try to get latest version if GitHub repo
        for url in urls:
            if 'github.com' in url and '/releases/latest' in url:
                latest_url = self.get_github_latest_release_url(url)
                if latest_url:
                    urls.insert(0, latest_url)
                    print(f"   Found latest release!")
                    break
        
        # Download
        dest_file = Path(f"/tmp/{driver_name}.zip")
        if self.download_with_fallback(driver_name, urls, dest_file):
            print(f"   ✅ Downloaded successfully")
            
            # Extract to appropriate location
            if os_type == 'macos':
                extract_dir = dest_dir / "macOS" / "PC_Specific"
            elif os_type == 'windows':
                extract_dir = dest_dir / "Windows" / "PC_Drivers"
            elif os_type == 'asahi':
                extract_dir = dest_dir / "Linux" / "Asahi"
            
            extract_dir.mkdir(parents=True, exist_ok=True)
            
            # Extract
            try:
                import zipfile
                with zipfile.ZipFile(dest_file, 'r') as zf:
                    zf.extractall(extract_dir)
                print(f"   ✅ Extracted to {extract_dir}")
                dest_file.unlink()
                return True
            except Exception as e:
                print(f"   ⚠️  Extract failed: {e}")
                return False
        
        return False
    
    def get_missing_drivers(self, required_drivers, os_type):
        """Check what's missing from archive"""
        missing = []
        
        if os_type == 'macos':
            search_dirs = [
                self.archive_dir / "macOS" / "Universal",
                self.archive_dir / "macOS" / "PC_Specific"
            ]
            
            for driver in required_drivers:
                found = False
                for search_dir in search_dirs:
                    if search_dir.exists():
                        matches = list(search_dir.rglob(f"{driver}*"))
                        if matches:
                            found = True
                            break
                if not found:
                    missing.append(driver)
        
        elif os_type == 'windows':
            search_dir = self.archive_dir / "Windows" / "PC_Drivers"
            for driver in required_drivers:
                if not search_dir.exists():
                    missing.append(driver)
                else:
                    matches = list(search_dir.rglob(f"*{driver}*"))
                    if not matches:
                        missing.append(driver)
        
        elif os_type == 'linux':
            # Linux modules usually from system
            # But check for Asahi drivers on ARM
            if 'asahi' in str(required_drivers).lower():
                asahi_dir = self.archive_dir / "Linux" / "Asahi"
                if not asahi_dir.exists() or len(list(asahi_dir.iterdir())) == 0:
                    missing.extend(required_drivers)
        
        return missing
    
    def auto_download_missing(self, required_drivers, os_type):
        """Automatically download any missing drivers"""
        print("="*60)
        print(f"🔍 Checking {os_type.upper()} drivers...")
        print("="*60)
        
        # Check internet
        if not self.check_internet():
            print("\n❌ No internet connection!")
            print("   Proceeding with available drivers only...")
            return False
        
        print("\n✅ Internet connected!")
        
        # Check what's missing
        missing = self.get_missing_drivers(required_drivers, os_type)
        
        if not missing:
            print(f"\n✅ All {len(required_drivers)} drivers present in archive!")
            return True
        
        print(f"\n⚠️  Missing {len(missing)}/{len(required_drivers)} drivers:")
        for driver in missing:
            print(f"   - {driver}")
        
        print(f"\n📥 Downloading missing drivers...")
        
        downloaded = 0
        for driver in missing:
            if self.smart_download(driver, os_type, self.archive_dir):
                downloaded += 1
        
        print(f"\n✅ Downloaded {downloaded}/{len(missing)} drivers")
        
        return downloaded > 0

def main():
    """Test the smart downloader"""
    downloader = SmartDownloader()
    
    # Test with some common drivers
    print("Testing Smart Downloader")
    print("="*60)
    
    # Test macOS
    test_drivers = ['Lilu', 'VirtualSMC', 'WhateverGreen']
    downloader.auto_download_missing(test_drivers, 'macos')

if __name__ == "__main__":
    main()
