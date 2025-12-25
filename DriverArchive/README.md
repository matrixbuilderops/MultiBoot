# Driver Archive - UNIVERSAL Coverage

This archive provides drivers for ALL scenarios:

## 📦 Structure:

### macOS/
- **Universal/** - Kexts needed on BOTH PC and Mac
- **PC_Specific/** - OpenCore kexts for Hackintosh
- **Mac_Specific/** - External boot helpers for Mac

### Windows/
- **PC_Drivers/** - Standard Windows drivers for PC
- **BootCamp_Drivers/** - Apple-specific drivers for Windows on Mac
- **ARM_Drivers/** - Windows ARM drivers for M1/M2/M3

### Linux/
- **x86_Common/** - Standard modules for PC and Intel Mac
- **Mac_Specific/** - Intel Mac hardware modules
- **Asahi/** - Full Asahi Linux stack for ARM Mac

### Firmware/
- Firmware files used across all platforms

## 🔄 Download Sources:

### macOS Kexts (Universal + PC_Specific):
- Lilu: https://github.com/acidanthera/Lilu/releases
- VirtualSMC: https://github.com/acidanthera/VirtualSMC/releases
- WhateverGreen: https://github.com/acidanthera/WhateverGreen/releases
- AppleALC: https://github.com/acidanthera/AppleALC/releases
- AirportItlwm: https://github.com/OpenIntelWireless/itlwm/releases
- IntelMausi: https://github.com/acidanthera/IntelMausi/releases
- RealtekRTL8111: https://github.com/Mieze/RTL8111_driver_for_OS_X/releases

### Windows Drivers (PC):
- Intel WiFi/Bluetooth/Ethernet: https://www.intel.com/content/www/us/en/download-center/home.html
- NVIDIA: https://www.nvidia.com/Download/index.aspx
- AMD: https://www.amd.com/en/support

### Windows Drivers (Boot Camp - for Mac):
- Download Boot Camp Support Software from Apple
- Or extract from macOS Boot Camp Assistant

### Linux Modules:
- Most modules copied from /lib/modules/ at runtime
- Asahi: https://github.com/AsahiLinux/

## 🎯 Usage:

The wrapper automatically:
1. Detects computer type (PC vs Mac)
2. Detects target OS
3. Selects appropriate archive section
4. Checks for required drivers
5. Downloads if missing (and internet available)
6. Injects drivers before boot

