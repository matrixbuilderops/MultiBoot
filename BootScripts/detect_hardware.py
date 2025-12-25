#!/usr/bin/env python3
"""
Hardware Detection System
Detects CPU, GPU, Network, Storage, Firmware
"""

import subprocess
import json
import re
from pathlib import Path

def run_cmd(cmd):
    """Run command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
        return result.stdout.strip()
    except:
        return ""

def detect_architecture():
    """Detect CPU architecture"""
    arch = run_cmd("uname -m")
    return arch if arch else "unknown"

def detect_cpu():
    """Detect CPU information"""
    cpu_info = {}
    
    # Try to read from /proc/cpuinfo
    cpuinfo = run_cmd("cat /proc/cpuinfo 2>/dev/null")
    if cpuinfo:
        # Get model name
        model_match = re.search(r'model name\s+:\s+(.+)', cpuinfo)
        if model_match:
            cpu_info['name'] = model_match.group(1).strip()
        
        # Count cores
        cores = cpuinfo.count('processor')
        cpu_info['cores'] = cores
        
        # Detect vendor
        if 'Intel' in cpuinfo:
            cpu_info['vendor'] = 'Intel'
        elif 'AMD' in cpuinfo:
            cpu_info['vendor'] = 'AMD'
        elif 'Apple' in cpuinfo or 'ARM' in cpuinfo:
            cpu_info['vendor'] = 'Apple'
        else:
            cpu_info['vendor'] = 'Unknown'
    
    return cpu_info

def detect_platform():
    """Detect platform (Intel/AMD/ARM)"""
    arch = detect_architecture()
    cpu = detect_cpu()
    
    if arch == "x86_64":
        vendor = cpu.get('vendor', '')
        if 'Intel' in vendor:
            return 'Intel'
        elif 'AMD' in vendor:
            return 'AMD'
        return 'x86_64'
    elif arch == "aarch64" or arch == "arm64":
        return 'ARM64'
    
    return 'Unknown'

def detect_firmware():
    """Detect firmware type (UEFI or BIOS)"""
    if Path("/sys/firmware/efi").exists():
        return "UEFI"
    return "BIOS"

def detect_gpu():
    """Detect GPU information"""
    gpus = []
    
    # Try lspci
    lspci_output = run_cmd("lspci 2>/dev/null | grep -i 'vga\\|3d\\|display'")
    
    if lspci_output:
        for line in lspci_output.split('\n'):
            if not line.strip():
                continue
                
            gpu_info = {}
            
            # Extract vendor and device IDs
            id_match = re.search(r'([0-9a-f]{4}):([0-9a-f]{4})', 
                                run_cmd(f"lspci -n | grep '{line[:7]}'"))
            if id_match:
                gpu_info['vendor_id'] = id_match.group(1)
                gpu_info['device_id'] = id_match.group(2)
            
            # Detect manufacturer
            if 'NVIDIA' in line or '10de:' in str(gpu_info.get('vendor_id', '')):
                gpu_info['manufacturer'] = 'NVIDIA'
            elif 'AMD' in line or 'ATI' in line or '1002:' in str(gpu_info.get('vendor_id', '')):
                gpu_info['manufacturer'] = 'AMD'
            elif 'Intel' in line or '8086:' in str(gpu_info.get('vendor_id', '')):
                gpu_info['manufacturer'] = 'Intel'
            elif 'Apple' in line:
                gpu_info['manufacturer'] = 'Apple'
            else:
                gpu_info['manufacturer'] = 'Unknown'
            
            gpu_info['description'] = line.split(':', 1)[1].strip() if ':' in line else line
            
            gpus.append(gpu_info)
    
    return gpus

def detect_network():
    """Detect network devices"""
    devices = []
    
    # Try lspci for network controllers
    lspci_output = run_cmd("lspci 2>/dev/null | grep -i 'network\\|ethernet\\|wireless\\|wi-fi'")
    
    if lspci_output:
        for line in lspci_output.split('\n'):
            if not line.strip():
                continue
            
            device_info = {}
            
            # Extract vendor:device IDs
            pci_id = line.split()[0]
            id_output = run_cmd(f"lspci -n -s {pci_id}")
            id_match = re.search(r'([0-9a-f]{4}):([0-9a-f]{4})', id_output)
            
            if id_match:
                device_info['vendor_id'] = id_match.group(1)
                device_info['device_id'] = id_match.group(2)
            
            # Determine type
            if 'Wireless' in line or 'Wi-Fi' in line or 'WiFi' in line:
                device_info['type'] = 'WiFi'
            else:
                device_info['type'] = 'Ethernet'
            
            device_info['description'] = line.split(':', 1)[1].strip() if ':' in line else line
            
            devices.append(device_info)
    
    return devices

def detect_storage():
    """Detect storage controllers"""
    controllers = []
    
    lspci_output = run_cmd("lspci 2>/dev/null | grep -i 'storage\\|sata\\|nvme\\|raid'")
    
    if lspci_output:
        for line in lspci_output.split('\n'):
            if not line.strip():
                continue
            
            controller = {
                'description': line.split(':', 1)[1].strip() if ':' in line else line
            }
            
            if 'NVMe' in line:
                controller['type'] = 'NVMe'
            elif 'SATA' in line:
                controller['type'] = 'SATA'
            elif 'RAID' in line:
                controller['type'] = 'RAID'
            else:
                controller['type'] = 'Unknown'
            
            controllers.append(controller)
    
    return controllers

def generate_fingerprint(hardware):
    """Generate hardware fingerprint"""
    parts = []
    
    # Add platform
    platform = hardware.get('platform', 'unknown').lower()
    parts.append(platform)
    
    # Add CPU info
    cpu = hardware.get('cpu', {})
    cpu_name = cpu.get('name', '').lower()
    cpu_simple = re.sub(r'[^a-z0-9]', '', cpu_name)[:20]
    if cpu_simple:
        parts.append(cpu_simple)
    
    # Add GPU IDs
    gpus = hardware.get('gpu', [])
    for gpu in gpus[:2]:  # Max 2 GPUs
        vendor = gpu.get('vendor_id', '')
        device = gpu.get('device_id', '')
        if vendor and device:
            parts.append(f"{vendor}{device}")
    
    return '_'.join(parts)

def detect_all():
    """Detect all hardware"""
    hardware = {
        'architecture': detect_architecture(),
        'platform': detect_platform(),
        'firmware': detect_firmware(),
        'cpu': detect_cpu(),
        'gpu': detect_gpu(),
        'network': detect_network(),
        'storage': detect_storage()
    }
    
    # Generate fingerprint
    hardware['fingerprint'] = generate_fingerprint(hardware)
    
    return hardware

def main():
    """Main detection routine"""
    print("=" * 60)
    print("Hardware Detection System")
    print("=" * 60)
    
    hardware = detect_all()
    
    # Save to HardwareProfiles
    profiles_dir = Path(__file__).parent.parent / "HardwareProfiles"
    profiles_dir.mkdir(parents=True, exist_ok=True)
    
    profile_file = profiles_dir / "current.json"
    with open(profile_file, 'w') as f:
        json.dump(hardware, f, indent=2)
    
    print(f"\n✅ Hardware profile saved to: {profile_file}")
    
    # Print summary
    print(f"\n📊 Detected Hardware:")
    print(f"  Architecture: {hardware['architecture']}")
    print(f"  Platform: {hardware['platform']}")
    print(f"  Firmware: {hardware['firmware']}")
    print(f"  CPU: {hardware['cpu'].get('name', 'Unknown')}")
    print(f"  GPUs: {len(hardware['gpu'])}")
    for gpu in hardware['gpu']:
        print(f"    - {gpu.get('manufacturer', 'Unknown')}: {gpu.get('description', 'Unknown')}")
    print(f"  Network: {len(hardware['network'])} devices")
    for net in hardware['network']:
        print(f"    - {net.get('type', 'Unknown')}: {net.get('description', 'Unknown')}")
    print(f"  Storage: {len(hardware['storage'])} controllers")
    print(f"\n🔖 Fingerprint: {hardware['fingerprint']}")
    
    return hardware

if __name__ == "__main__":
    main()
