#!/usr/bin/env python3
"""
Universal MultiBoot - Main Boot Menu
This runs at boot time and presents the user with OS choices
"""

import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from detect_hardware import detect_all
from driver_mapper import generate_manifest
from universal_wrapper import UniversalWrapper
import json

def clear_screen():
    """Clear terminal"""
    os.system('clear')

def print_header():
    """Print boot menu header"""
    print("\n" + "="*60)
    print("    🔥 UNIVERSAL MULTIBOOT - GENESIS")
    print("="*60)

def show_hardware_info(hardware):
    """Display detected hardware"""
    print(f"\n💻 Detected Hardware:")
    print(f"   CPU: {hardware.get('cpu', {}).get('name', 'Unknown')}")
    print(f"   Platform: {hardware.get('platform', 'Unknown')}")
    print(f"   Firmware: {hardware.get('firmware', 'Unknown')}")
    
    gpus = hardware.get('gpu', [])
    if gpus:
        print(f"   GPU: {gpus[0].get('manufacturer', 'Unknown')} - {gpus[0].get('description', '')[:50]}")
    
    networks = hardware.get('network', [])
    wifi = [n for n in networks if n.get('type') == 'WiFi']
    if wifi:
        print(f"   WiFi: {wifi[0].get('description', '')[:50]}")

def show_os_menu(wrapper, hardware):
    """Show OS selection menu"""
    computer_type = wrapper.detect_computer_type()
    
    print(f"\n🖥️  Computer Type: {computer_type}")
    print("\n📋 Available Operating Systems:")
    print("\n  1. macOS")
    
    strategy = wrapper.get_boot_strategy(computer_type, 'macos')
    print(f"     Method: {strategy.get('description', 'N/A')}")
    
    print("\n  2. Windows")
    strategy = wrapper.get_boot_strategy(computer_type, 'windows')
    print(f"     Method: {strategy.get('description', 'N/A')}")
    
    print("\n  3. Linux (Ubuntu)")
    strategy = wrapper.get_boot_strategy(computer_type, 'linux')
    print(f"     Method: {strategy.get('description', 'N/A')}")
    
    print("\n  4. Refresh Hardware Detection")
    print("  5. Advanced Options")
    print("  6. Reboot")
    print("  7. Power Off")

def check_archive_status(os_choice):
    """Check if drivers are in archive"""
    base_dir = Path(__file__).parent.parent
    archive_dir = base_dir / "DriverArchive"
    
    if os_choice == 'macos':
        kext_dirs = [
            archive_dir / "macOS" / "Universal",
            archive_dir / "macOS" / "PC_Specific"
        ]
        total = 0
        for kdir in kext_dirs:
            if kdir.exists():
                total += len(list(kdir.rglob("*.kext")))
        return total
    
    elif os_choice == 'windows':
        driver_dir = archive_dir / "Windows" / "PC_Drivers"
        if driver_dir.exists():
            return len(list(driver_dir.rglob("*.exe"))) + len(list(driver_dir.rglob("*.inf")))
        return 0
    
    elif os_choice == 'linux':
        return len(list(Path("/lib/modules").rglob("*.ko"))) if Path("/lib/modules").exists() else 0
    
    return 0

def boot_os(os_choice, wrapper):
    """Boot selected OS"""
    print(f"\n{'='*60}")
    print(f"🚀 Preparing to boot {os_choice.upper()}...")
    print(f"{'='*60}")
    
    # Check archive
    driver_count = check_archive_status(os_choice)
    print(f"\n📦 Archive Status: {driver_count} drivers/modules available")
    
    # Configure boot
    config = wrapper.configure_boot(os_choice)
    
    print(f"\n⚙️  Configuration complete!")
    print(f"\n🔄 Booting {os_choice.upper()} in 3 seconds...")
    print(f"    (Press Ctrl+C to cancel)")
    
    try:
        import time
        time.sleep(3)
        
        # Here we would actually boot the OS
        # For now, just show what would happen
        print(f"\n✅ Would now boot {os_choice} with wrapper!")
        print(f"   Method: {config['strategy'].get('method')}")
        
        # In real implementation:
        # if os_choice == 'macos':
        #     exec_opencore()
        # elif os_choice == 'windows':
        #     chainload_windows()
        # elif os_choice == 'linux':
        #     boot_linux_kernel()
        
    except KeyboardInterrupt:
        print("\n\n❌ Boot cancelled!")
        return False
    
    return True

def main_menu():
    """Main boot menu loop"""
    clear_screen()
    print_header()
    
    print("\n🔍 Detecting hardware...")
    
    # Detect hardware
    hardware = detect_all()
    
    # Initialize wrapper
    wrapper = UniversalWrapper()
    
    while True:
        clear_screen()
        print_header()
        show_hardware_info(hardware)
        show_os_menu(wrapper, hardware)
        
        print("\n" + "="*60)
        choice = input("\nSelect option (1-7): ").strip()
        
        if choice == '1':
            if boot_os('macos', wrapper):
                break
        elif choice == '2':
            if boot_os('windows', wrapper):
                break
        elif choice == '3':
            if boot_os('linux', wrapper):
                break
        elif choice == '4':
            print("\n🔄 Refreshing hardware detection...")
            hardware = detect_all()
            input("\nPress Enter to continue...")
        elif choice == '5':
            print("\n⚙️  Advanced Options - Coming soon!")
            input("\nPress Enter to continue...")
        elif choice == '6':
            print("\n🔄 Rebooting...")
            os.system('reboot')
            break
        elif choice == '7':
            print("\n⚡ Powering off...")
            os.system('poweroff')
            break
        else:
            print("\n❌ Invalid choice!")
            input("\nPress Enter to continue...")

if __name__ == "__main__":
    try:
        main_menu()
    except KeyboardInterrupt:
        print("\n\n❌ Boot cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
