#!/usr/bin/env python3
"""
Driver Mapping System
Maps detected hardware to required drivers/kexts/modules
"""

import json
from pathlib import Path

def map_gpu_to_kexts(gpu_info):
    """Map GPU to macOS kexts"""
    kexts = ['Lilu.kext', 'WhateverGreen.kext']  # Always needed
    
    manufacturer = gpu_info.get('manufacturer', '').lower()
    
    if 'nvidia' in manufacturer:
        # NVIDIA GPUs need WhateverGreen
        pass  # Already in list
    elif 'amd' in manufacturer:
        # AMD GPUs might need NootedRed for newer cards
        kexts.append('NootedRed.kext')
    elif 'intel' in manufacturer:
        # Intel iGPUs work with WhateverGreen
        pass
    
    return kexts

def map_network_to_kexts(network_info):
    """Map network device to macOS kexts"""
    kexts = []
    
    vendor_id = network_info.get('vendor_id', '')
    device_type = network_info.get('type', '')
    
    # Intel WiFi
    if vendor_id == '8086' and device_type == 'WiFi':
        kexts.append('AirportItlwm.kext')
        kexts.append('IntelBluetoothFirmware.kext')
    
    # Broadcom WiFi
    elif vendor_id == '14e4':
        kexts.append('AirportBrcmFixup.kext')
        kexts.append('BrcmPatchRAM3.kext')
    
    # Intel Ethernet
    elif vendor_id == '8086' and device_type == 'Ethernet':
        kexts.append('IntelMausi.kext')
    
    # Realtek Ethernet
    elif vendor_id == '10ec':
        kexts.append('RealtekRTL8111.kext')
    
    return kexts

def map_macos_drivers(hardware):
    """Map hardware to macOS kexts"""
    kexts = set()
    
    # Core kexts (always needed)
    kexts.add('Lilu.kext')
    kexts.add('VirtualSMC.kext')
    kexts.add('WhateverGreen.kext')
    kexts.add('AppleALC.kext')
    
    # GPU-specific
    for gpu in hardware.get('gpu', []):
        for kext in map_gpu_to_kexts(gpu):
            kexts.add(kext)
    
    # Network-specific
    for net in hardware.get('network', []):
        for kext in map_network_to_kexts(net):
            kexts.add(kext)
    
    # USB (always helpful)
    kexts.add('USBInjectAll.kext')
    
    # Platform-specific
    platform = hardware.get('platform', '')
    if platform == 'AMD':
        kexts.add('AMDRyzenCPUPowerManagement.kext')
    
    return sorted(list(kexts))

def map_windows_drivers(hardware):
    """Map hardware to Windows drivers"""
    drivers = []
    
    # Network drivers
    for net in hardware.get('network', []):
        vendor_id = net.get('vendor_id', '')
        device_type = net.get('type', '')
        
        if vendor_id == '8086' and device_type == 'WiFi':
            drivers.append('Intel_WiFi_Win10.exe')
        elif vendor_id == '8086' and device_type == 'Ethernet':
            drivers.append('Intel_Ethernet_Win10.exe')
        elif vendor_id == '10ec':
            drivers.append('Realtek_Ethernet_Win10.exe')
    
    # GPU drivers
    for gpu in hardware.get('gpu', []):
        manufacturer = gpu.get('manufacturer', '').lower()
        
        if 'nvidia' in manufacturer:
            drivers.append('NVIDIA_GeForce_Win10.exe')
        elif 'amd' in manufacturer:
            drivers.append('AMD_Radeon_Win10.exe')
        elif 'intel' in manufacturer:
            drivers.append('Intel_Graphics_Win10.exe')
    
    # Chipset
    platform = hardware.get('platform', '')
    if platform == 'Intel':
        drivers.append('Intel_Chipset_Win10.exe')
    elif platform == 'AMD':
        drivers.append('AMD_Chipset_Win10.exe')
    
    return sorted(list(set(drivers)))

def map_linux_modules(hardware):
    """Map hardware to Linux kernel modules"""
    modules = []
    
    # Network modules
    for net in hardware.get('network', []):
        vendor_id = net.get('vendor_id', '')
        device_type = net.get('type', '')
        
        if vendor_id == '8086' and device_type == 'WiFi':
            modules.extend(['iwlwifi', 'iwlmvm'])
        elif vendor_id == '8086' and device_type == 'Ethernet':
            modules.append('e1000e')
        elif vendor_id == '10ec' and device_type == 'Ethernet':
            modules.append('r8169')
    
    # GPU modules
    for gpu in hardware.get('gpu', []):
        manufacturer = gpu.get('manufacturer', '').lower()
        
        if 'nvidia' in manufacturer:
            modules.extend(['nvidia', 'nvidia_drm', 'nvidia_modeset'])
        elif 'amd' in manufacturer:
            modules.append('amdgpu')
        elif 'intel' in manufacturer:
            modules.append('i915')
    
    return sorted(list(set(modules)))

def generate_manifest(hardware):
    """Generate complete driver manifest"""
    manifest = {
        'fingerprint': hardware.get('fingerprint', 'unknown'),
        'platform': hardware.get('platform', 'unknown'),
        'firmware': hardware.get('firmware', 'unknown'),
        'macos': {
            'kexts': map_macos_drivers(hardware)
        },
        'windows': {
            'drivers': map_windows_drivers(hardware)
        },
        'linux': {
            'modules': map_linux_modules(hardware)
        }
    }
    
    return manifest

def main():
    """Main mapping routine"""
    print("=" * 60)
    print("Driver Mapping System")
    print("=" * 60)
    
    # Load hardware profile
    profiles_dir = Path(__file__).parent.parent / "HardwareProfiles"
    profile_file = profiles_dir / "current.json"
    
    if not profile_file.exists():
        print("\n❌ No hardware profile found!")
        print("   Run detect_hardware.py first")
        return False
    
    with open(profile_file, 'r') as f:
        hardware = json.load(f)
    
    print(f"\n📋 Loaded profile: {hardware.get('fingerprint', 'unknown')}")
    
    # Generate manifest
    manifest = generate_manifest(hardware)
    
    # Save manifest
    manifest_file = profiles_dir / "current_manifest.json"
    with open(manifest_file, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"✅ Driver manifest saved to: {manifest_file}")
    
    # Print summary
    print(f"\n📦 Required Drivers:")
    print(f"\n🍎 macOS ({len(manifest['macos']['kexts'])} kexts):")
    for kext in manifest['macos']['kexts']:
        print(f"   - {kext}")
    
    print(f"\n🪟 Windows ({len(manifest['windows']['drivers'])} drivers):")
    for driver in manifest['windows']['drivers']:
        print(f"   - {driver}")
    
    print(f"\n🐧 Linux ({len(manifest['linux']['modules'])} modules):")
    for module in manifest['linux']['modules']:
        print(f"   - {module}")
    
    return True

if __name__ == "__main__":
    main()
