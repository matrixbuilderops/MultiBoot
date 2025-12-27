#!/bin/bash
# Comprehensive driver archive expansion for all platforms and scenarios

ARCHIVE_DIR="/run/media/phantom-orchestrator/MultiBoot_Archive/DriverArchive"
mkdir -p "$ARCHIVE_DIR"/{windows,macos,linux}/{intel,amd,nvidia,audio,network,storage,usb}

echo "=== EXPANDING WINDOWS DRIVERS ==="
# Windows essential drivers (generic INF-based)
cd "$ARCHIVE_DIR/windows"
curl -L "https://github.com/virtio-win/virtio-win-pkg-scripts/archive/refs/heads/master.zip" -o virtio-win.zip
curl -L "https://downloadmirror.intel.com/744753/Intel-Chipset-Software-Installation-Utility.zip" -o intel-chipset.zip
curl -L "https://www.nvidia.com/content/DriverDownloads/confirmation.php?url=/Windows/551.86/551.86-desktop-win10-win11-64bit-international-dch-whql.exe&lang=us&type=TITAN" -o nvidia-latest.exe 2>/dev/null || echo "NVIDIA manual"
# AMD Chipset drivers
curl -L "https://drivers.amd.com/drivers/amd-chipset-software-installer.exe" -o amd-chipset.exe 2>/dev/null || echo "AMD manual"

echo "=== EXPANDING MACOS KEXTS (All Mac Models) ==="
cd "$ARCHIVE_DIR/macos"
# Comprehensive Kext collection for Intel and Apple Silicon
git clone https://github.com/acidanthera/Lilu.git 2>/dev/null || echo "Lilu exists"
git clone https://github.com/acidanthera/WhateverGreen.git 2>/dev/null || echo "WhateverGreen exists"
git clone https://github.com/acidanthera/AppleALC.git 2>/dev/null || echo "AppleALC exists"
git clone https://github.com/acidanthera/VirtualSMC.git 2>/dev/null || echo "VirtualSMC exists"
git clone https://github.com/acidanthera/NVMeFix.git 2>/dev/null || echo "NVMeFix exists"
git clone https://github.com/acidanthera/AirportBrcmFixup.git 2>/dev/null || echo "AirportBrcmFixup exists"
git clone https://github.com/acidanthera/BrcmPatchRAM.git 2>/dev/null || echo "BrcmPatchRAM exists"
git clone https://github.com/acidanthera/IntelMausi.git 2>/dev/null || echo "IntelMausi exists"
git clone https://github.com/acidanthera/RTL8111.git 2>/dev/null || echo "RTL8111 exists"
git clone https://github.com/acidanthera/VoodooPS2.git 2>/dev/null || echo "VoodooPS2 exists"
git clone https://github.com/acidanthera/VoodooInput.git 2>/dev/null || echo "VoodooInput exists"
git clone https://github.com/acidanthera/VoodooI2C.git 2>/dev/null || echo "VoodooI2C exists"
git clone https://github.com/acidanthera/CpuTscSync.git 2>/dev/null || echo "CpuTscSync exists"
git clone https://github.com/acidanthera/RestrictEvents.git 2>/dev/null || echo "RestrictEvents exists"
git clone https://github.com/acidanthera/FeatureUnlock.git 2>/dev/null || echo "FeatureUnlock exists"

echo "=== EXPANDING LINUX DRIVERS ==="
cd "$ARCHIVE_DIR/linux"
# Firmware packages
wget -q http://archive.ubuntu.com/ubuntu/pool/main/l/linux-firmware/linux-firmware_20240318.git3b128b60-0ubuntu2_all.deb -O linux-firmware.deb || echo "Firmware skip"
wget -q http://archive.ubuntu.com/ubuntu/pool/restricted/l/linux-restricted-modules/nvidia-driver-550_550.54.14-0ubuntu1_amd64.deb -O nvidia.deb 2>/dev/null || echo "NVIDIA skip"
wget -q http://archive.ubuntu.com/ubuntu/pool/restricted/l/linux-restricted-modules/amdgpu-pro-23.40_23.40-1781449.22.04_amd64.deb -O amdgpu.deb 2>/dev/null || echo "AMDGPU skip"

echo "=== VERIFYING ARCHIVE SIZE ==="
du -sh "$ARCHIVE_DIR"
find "$ARCHIVE_DIR" -type f | wc -l
