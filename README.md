# Universal MultiBoot Wrapper - Quick Start Guide

## 🎯 What Is This?

A revolutionary multiboot system that allows you to run **macOS, Windows, and Linux on ANY hardware** from a single 2TB drive. Just plug it into any computer (Mac or PC, UEFI or BIOS) and boot your OS of choice with automatic hardware detection and driver injection!

## ✨ Key Features

- 🔄 **Universal Compatibility**: Works on Intel/AMD, UEFI/BIOS, Mac/PC
- 🤖 **Automatic Hardware Detection**: Detects CPU, GPU, network, storage at boot
- 📦 **Pre-cached Drivers**: No internet needed - all drivers stored locally
- 🎨 **Three OS Profiles**: macOS (via OpenCore), Windows, Linux (Ubuntu)
- 🚀 **One-Click Setup**: Automated configuration based on detected hardware

## 📁 Project Structure

```
UniversalWrapper/
├── universal_manager.py          # Main control script
├── BootScripts/
│   ├── detect_hardware.py        # Hardware detection engine
│   ├── driver_mapper.py          # Maps hardware to drivers
│   └── build_kext_archive.py     # Downloads macOS kexts
├── HardwareProfiles/
│   ├── current.json              # Current system hardware
│   ├── current_manifest.json     # Required drivers for current system
│   └── *.json                    # Cached profiles for different hardware
├── DriverArchive/
│   ├── macOS/
│   │   ├── Kexts/               # All macOS kexts
│   │   └── ACPI/                # ACPI patches
│   ├── Windows/
│   │   ├── Network/             # Windows network drivers
│   │   ├── Storage/             # Windows storage drivers
│   │   ├── Graphics/            # Windows GPU drivers
│   │   └── Chipset/             # Windows chipset drivers
│   └── Linux/
│       └── modules/             # Linux kernel modules
└── OpCoreEngine/
    └── OpCore-Simplify/         # Modified OpCore-Simplify
```

## 🚀 Quick Start

### 1. Check System Status
```bash
python3 universal_manager.py status
```

### 2. Run Full Setup (Recommended for first time)
```bash
python3 universal_manager.py full-setup
```

This will:
- ✅ Detect your hardware
- ✅ Map required drivers for all 3 OSes
- ✅ Download macOS kexts (~100MB)
- ✅ Generate EFI configurations

### 3. Individual Steps (Advanced)

Detect hardware only:
```bash
python3 universal_manager.py detect
```

Map drivers for detected hardware:
```bash
python3 universal_manager.py map
```

Build kext archive:
```bash
python3 universal_manager.py build-kexts
```

Generate EFI for specific OS:
```bash
python3 universal_manager.py generate-efi --os macos
python3 universal_manager.py generate-efi --os windows
python3 universal_manager.py generate-efi --os linux
```

## 📊 Current System Detection Example

```json
{
  "platform": "Intel",
  "firmware": "UEFI",
  "cpu": {
    "name": "Intel(R) Core(TM) i7-4860HQ CPU @ 2.40GHz",
    "cores": 8
  },
  "gpu": [
    {
      "manufacturer": "NVIDIA",
      "device_id": "13d7",
      "description": "NVIDIA Corporation GM204M"
    }
  ],
  "network": [
    {
      "type": "WiFi",
      "vendor_id": "8086",
      "description": "Intel Wireless 7260"
    },
    {
      "type": "Ethernet",
      "vendor_id": "10ec",
      "description": "Realtek RTL8111"
    }
  ]
}
```

## 🎯 Detected Driver Requirements

### macOS (7 kexts required)
- Lilu.kext (Core patching framework)
- VirtualSMC.kext (SMC emulation)
- WhateverGreen.kext (Graphics patching)
- AppleALC.kext (Audio codec support)
- AirportItlwm.kext (Intel WiFi)
- RealtekRTL8111.kext (Realtek Ethernet)
- USBInjectAll.kext (USB port injection)

### Windows (4 drivers required)
- Intel_WiFi_Win10_64.exe
- Realtek_Ethernet_Win10_64.exe
- NVIDIA_GeForce_Win10_64.exe
- Intel_Chipset_Win10_64.exe

### Linux (5 modules required)
- iwlwifi (Intel WiFi)
- iwlmvm (Intel WiFi management)
- r8169 (Realtek Ethernet)
- nouveau (NVIDIA graphics - open source)
- nvidia (NVIDIA graphics - proprietary)

## 🔧 How It Works

### Boot Process Flow

```
1. Computer boots from 2TB drive
   ↓
2. GRUB bootloader (hybrid UEFI/BIOS)
   ↓
3. Hardware detection script runs
   ↓
4. Generate hardware fingerprint
   ↓
5. Check cached profile OR create new profile
   ↓
6. Load driver manifest
   ↓
7. User selects OS (macOS/Windows/Linux)
   ↓
8. Inject appropriate drivers/kexts
   ↓
9. Boot selected OS with correct configuration
```

### macOS Boot Flow (via OpenCore)
```
GRUB → detect_hardware.py → driver_mapper.py
  ↓
Generate config.plist with hardware-specific kexts
  ↓
Load OpenCore with dynamic configuration
  ↓
Boot macOS with injected kexts
```

### Windows Boot Flow
```
GRUB → detect_hardware.py → driver_mapper.py
  ↓
Copy drivers to Windows\System32\drivers
  ↓
Update registry for driver loading
  ↓
Boot Windows with drivers pre-installed
```

### Linux Boot Flow
```
GRUB → detect_hardware.py → driver_mapper.py
  ↓
Add modules to initramfs
  ↓
Configure module loading
  ↓
Boot Linux with correct modules
```

## 📦 2TB Drive Layout

```
/dev/sdd (1.8TB Physical Drive)
├── sdd1: 512MB   EFI Partition (FAT32)
│   ├── /EFI/BOOT/       # GRUB bootloader
│   ├── /EFI/OC/         # OpenCore for macOS
│   └── /EFI/Microsoft/  # Windows Boot Manager
│
├── sdd2: 600GB   Windows 10 (NTFS)
│
├── sdd3: 663GB   macOS (APFS)
│
└── sdd4: 599.5GB Ubuntu (ext4)
```

### UniversalWrapper Installation
The UniversalWrapper system (~100-500MB after full setup) can be stored:
- Option 1: On EFI partition (if 512MB is enough after GRUB+OpenCore)
- Option 2: Create new 2GB partition for wrapper
- Option 3: Store on Ubuntu partition (recommended)

## 🛠️ Next Steps

### Phase 1: Hardware Detection ✅ DONE
- [x] Hardware profiler created
- [x] Driver mapper implemented
- [x] JSON profile generation working

### Phase 2: Driver Archive Builder ✅ IN PROGRESS
- [x] Kext downloader script created
- [ ] Download all 15+ essential kexts
- [ ] Windows driver pack integration
- [ ] Linux module archive

### Phase 3: macOS Wrapper (OpenCore)
- [ ] Integrate OpCore-Simplify for dynamic config.plist
- [ ] Create boot-time kext injection
- [ ] ACPI patch automation
- [ ] SMBIOS selection based on hardware

### Phase 4: Windows Wrapper
- [ ] Windows PE helper
- [ ] Driver injection system
- [ ] Registry automation
- [ ] Boot configuration

### Phase 5: Linux Wrapper
- [ ] Initramfs builder with hardware detection
- [ ] Module injection system
- [ ] GRUB configuration
- [ ] Kernel parameter optimization

### Phase 6: Universal GRUB
- [ ] Hybrid UEFI+BIOS bootloader
- [ ] Boot menu with hardware info
- [ ] Fallback/recovery options
- [ ] Theme/customization

### Phase 7: Deploy to 2TB Drive
- [ ] Copy UniversalWrapper to drive
- [ ] Install GRUB to EFI partition
- [ ] Test on multiple hardware configs
- [ ] Documentation and troubleshooting

## 🎓 Technical Details

### Hardware Fingerprinting
Each hardware configuration gets a unique fingerprint:
```
{platform}_{cpu_model}_{gpu_vendor_ids}
Example: intel_corei74860hq_10de13d7
```

This allows caching of driver configurations for faster subsequent boots.

### Driver Archive Strategy
- **macOS**: Download from Dortania builds + GitHub releases
- **Windows**: Extract from Windows Driver Kit + OEM packs
- **Linux**: Bundle common modules from multiple kernel versions

### Automation Philosophy
Based on OpCore-Simplify's approach:
1. Detect hardware automatically
2. Select appropriate drivers/kexts
3. Generate configuration dynamically
4. Apply ACPI patches as needed
5. Minimize manual intervention

## 📈 Future Enhancements

- 🌐 Cloud profile sync (share hardware configs)
- 🔒 Encrypted driver archive
- 🎨 Custom boot themes
- 📱 Mobile app for boot selection
- 🤖 AI-powered driver selection
- 🔄 Automatic driver updates
- 🛡️ Secure boot support
- 🎮 Gaming performance optimization

## 🤝 Contributing

This is a custom project built on top of:
- [OpCore-Simplify](https://github.com/lzhoang2801/OpCore-Simplify)
- [OpenCore](https://github.com/acidanthera/OpenCorePkg)
- [Dortania Guide](https://dortania.github.io/OpenCore-Install-Guide/)

## 📝 License

Based on OpCore-Simplify (BSD 3-Clause License) and OpenCore.

---

**Built with passion for universal computing! 🚀**
