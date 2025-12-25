#!/usr/bin/env python3
"""
OpenCore Configuration Generator & Kext Injector
Generates OpenCore config.plist dynamically based on detected hardware
"""

import json
import plistlib
from pathlib import Path
import shutil

class OpenCoreInjector:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.hardware_profile = self.load_hardware()
        self.manifest = self.load_manifest()
        self.archive_dir = self.base_dir / "DriverArchive"
        
    def load_hardware(self):
        """Load hardware profile"""
        profile_file = self.base_dir / "HardwareProfiles" / "current.json"
        if profile_file.exists():
            with open(profile_file, 'r') as f:
                return json.load(f)
        return {}
    
    def load_manifest(self):
        """Load driver manifest"""
        manifest_file = self.base_dir / "HardwareProfiles" / "current_manifest.json"
        if manifest_file.exists():
            with open(manifest_file, 'r') as f:
                return json.load(f)
        return {}
    
    def get_required_kexts(self, computer_type):
        """Get kexts needed based on computer type"""
        kexts = self.manifest.get('macos', {}).get('kexts', [])
        
        if computer_type in ['INTEL_PC', 'AMD_PC']:
            # Hackintosh - needs all kexts
            return kexts
        else:
            # Mac - only needs universal kexts
            universal = ['Lilu.kext', 'VirtualSMC.kext', 'AppleALC.kext']
            return [k for k in kexts if k in universal]
    
    def find_kexts_in_archive(self, required_kexts):
        """Find kext files in archive"""
        found = {}
        
        # Search in both Universal and PC_Specific
        search_dirs = [
            self.archive_dir / "macOS" / "Universal",
            self.archive_dir / "macOS" / "PC_Specific"
        ]
        
        for kext_name in required_kexts:
            for search_dir in search_dirs:
                if not search_dir.exists():
                    continue
                
                # Find kext (could be nested in Release folder, etc)
                matches = list(search_dir.rglob(kext_name))
                if matches:
                    found[kext_name] = matches[0]
                    break
        
        return found
    
    def generate_base_config(self, computer_type):
        """Generate base OpenCore config.plist"""
        
        config = {
            'ACPI': {
                'Add': [],
                'Delete': [],
                'Patch': [],
                'Quirks': {
                    'FadtEnableReset': False,
                    'NormalizeHeaders': False,
                    'RebaseRegions': False,
                    'ResetHwSig': False,
                    'ResetLogoStatus': False
                }
            },
            'Booter': {
                'MmioWhitelist': [],
                'Patch': [],
                'Quirks': {
                    'AvoidRuntimeDefrag': True,
                    'DevirtualiseMmio': True,
                    'DisableSingleUser': False,
                    'DisableVariableWrite': False,
                    'DiscardHibernateMap': False,
                    'EnableSafeModeSlide': True,
                    'EnableWriteUnprotector': True,
                    'ForceExitBootServices': False,
                    'ProtectMemoryRegions': False,
                    'ProtectSecureBoot': False,
                    'ProtectUefiServices': False,
                    'ProvideCustomSlide': True,
                    'RebuildAppleMemoryMap': True,
                    'SetupVirtualMap': True,
                    'SignalAppleOS': False,
                    'SyncRuntimePermissions': True
                }
            },
            'DeviceProperties': {
                'Add': {},
                'Delete': {}
            },
            'Kernel': {
                'Add': [],  # Kexts will be added here
                'Block': [],
                'Emulate': {
                    'Cpuid1Data': bytearray(16),
                    'Cpuid1Mask': bytearray(16),
                    'DummyPowerManagement': False,
                    'MaxKernel': '',
                    'MinKernel': ''
                },
                'Force': [],
                'Patch': [],
                'Quirks': {
                    'AppleCpuPmCfgLock': False,
                    'AppleXcpmCfgLock': False,
                    'AppleXcpmExtraMsrs': False,
                    'AppleXcpmForceBoost': False,
                    'CustomSMBIOSGuid': False,
                    'DisableIoMapper': True,
                    'DisableLinkeditJettison': True,
                    'DisableRtcChecksum': False,
                    'ExtendBTFeatureFlags': False,
                    'ExternalDiskIcons': False,
                    'ForceSecureBootScheme': False,
                    'IncreasePciBarSize': False,
                    'LapicKernelPanic': False,
                    'LegacyCommpage': False,
                    'PanicNoKextDump': True,
                    'PowerTimeoutKernelPanic': True,
                    'ThirdPartyDrives': False,
                    'XhciPortLimit': True
                }
            },
            'Misc': {
                'BlessOverride': [],
                'Boot': {
                    'ConsoleAttributes': 0,
                    'HibernateMode': 'None',
                    'HideAuxiliary': False,
                    'PickerAttributes': 0,
                    'PickerAudioAssist': False,
                    'PickerMode': 'Builtin',
                    'PickerVariant': 'Default',
                    'PollAppleHotKeys': False,
                    'ShowPicker': True,
                    'TakeoffDelay': 0,
                    'Timeout': 5
                },
                'Debug': {
                    'AppleDebug': False,
                    'ApplePanic': True,
                    'DisableWatchDog': True,
                    'DisplayLevel': 2147483650,
                    'SerialInit': False,
                    'SysReport': False,
                    'Target': 3
                },
                'Entries': [],
                'Security': {
                    'AllowSetDefault': True,
                    'ApECID': 0,
                    'AuthRestart': False,
                    'BlacklistAppleUpdate': True,
                    'DmgLoading': 'Signed',
                    'EnablePassword': False,
                    'ExposeSensitiveData': 6,
                    'HaltLevel': 2147483648,
                    'PasswordHash': bytearray(),
                    'PasswordSalt': bytearray(),
                    'ScanPolicy': 0,
                    'SecureBootModel': 'Disabled',
                    'Vault': 'Optional'
                },
                'Tools': []
            },
            'NVRAM': {
                'Add': {
                    '7C436110-AB2A-4BBB-A880-FE41995C9F82': {
                        'boot-args': 'debug=0x100 keepsyms=1',
                        'csr-active-config': bytearray([0x67, 0x00, 0x00, 0x00]),
                        'prev-lang:kbd': bytearray(b'en-US:0')
                    }
                },
                'Delete': {
                    '7C436110-AB2A-4BBB-A880-FE41995C9F82': [
                        'boot-args'
                    ]
                },
                'LegacyOverwrite': False,
                'LegacySchema': {},
                'WriteFlash': True
            },
            'PlatformInfo': {
                'Automatic': True,
                'CustomMemory': False,
                'Generic': {
                    'AdviseFeatures': False,
                    'MaxBIOSVersion': False,
                    'ProcessorType': 0,
                    'ROM': bytearray(6),
                    'SpoofVendor': True,
                    'SystemMemoryStatus': 'Auto',
                    'SystemProductName': 'iMac19,1',  # Will be customized
                    'SystemSerialNumber': 'PLACEHOLDER',
                    'SystemUUID': 'PLACEHOLDER',
                    'MLB': 'PLACEHOLDER'
                },
                'UpdateDataHub': True,
                'UpdateNVRAM': True,
                'UpdateSMBIOS': True,
                'UpdateSMBIOSMode': 'Create'
            },
            'UEFI': {
                'APFS': {
                    'EnableJumpstart': True,
                    'GlobalConnect': False,
                    'HideVerbose': True,
                    'JumpstartHotPlug': False,
                    'MinDate': 0,
                    'MinVersion': 0
                },
                'AppleInput': {
                    'AppleEvent': 'Builtin',
                    'CustomDelays': False,
                    'KeyInitialDelay': 50,
                    'KeySubsequentDelay': 5,
                    'PointerSpeedDiv': 1,
                    'PointerSpeedMul': 1
                },
                'Audio': {
                    'AudioCodec': 0,
                    'AudioDevice': 'PciRoot(0x0)/Pci(0x1f,0x3)',
                    'AudioOutMask': 1,
                    'AudioSupport': False,
                    'DisconnectHda': False,
                    'MaximumGain': -15,
                    'MinimumAssistGain': -30,
                    'MinimumAudibleGain': -55,
                    'PlayChime': 'Auto',
                    'ResetTrafficClass': False,
                    'SetupDelay': 0
                },
                'ConnectDrivers': True,
                'Drivers': [
                    'OpenRuntime.efi',
                    'OpenCanopy.efi',
                    'HfsPlus.efi'
                ],
                'Input': {
                    'KeyFiltering': False,
                    'KeyForgetThreshold': 5,
                    'KeySupport': True,
                    'KeySupportMode': 'Auto',
                    'KeySwap': False,
                    'PointerSupport': False,
                    'PointerSupportMode': '',
                    'TimerResolution': 50000
                },
                'Output': {
                    'ClearScreenOnModeSwitch': False,
                    'ConsoleMode': '',
                    'DirectGopRendering': False,
                    'ForceResolution': False,
                    'GopPassThrough': 'Disabled',
                    'IgnoreTextInGraphics': False,
                    'InitialMode': 0,
                    'ProvideConsoleGop': True,
                    'ReconnectGraphicsOnConnect': False,
                    'ReconnectOnResChange': False,
                    'ReplaceTabWithSpace': False,
                    'Resolution': 'Max',
                    'SanitiseClearScreen': False,
                    'TextRenderer': 'BuiltinGraphics',
                    'UgaPassThrough': False
                },
                'ProtocolOverrides': {
                    'AppleAudio': False,
                    'AppleBootPolicy': False,
                    'AppleDebugLog': False,
                    'AppleEg2Info': False,
                    'AppleFramebufferInfo': False,
                    'AppleImageConversion': False,
                    'AppleImg4Verification': False,
                    'AppleKeyMap': False,
                    'AppleRtcRam': False,
                    'AppleSecureBoot': False,
                    'AppleSmcIo': False,
                    'AppleUserInterfaceTheme': False,
                    'DataHub': False,
                    'DeviceProperties': False,
                    'FirmwareVolume': False,
                    'HashServices': False,
                    'OSInfo': False,
                    'PciIo': False,
                    'UnicodeCollation': False
                },
                'Quirks': {
                    'ActivateHpetSupport': False,
                    'DisableSecurityPolicy': False,
                    'EnableVectorAcceleration': True,
                    'ExitBootServicesDelay': 0,
                    'ForceOcWriteFlash': False,
                    'ForgeUefiSupport': False,
                    'IgnoreInvalidFlexRatio': False,
                    'ReleaseUsbOwnership': False,
                    'ReloadOptionRoms': False,
                    'RequestBootVarRouting': True,
                    'ResizeGpuBars': -1,
                    'TscSyncTimeout': 0,
                    'UnblockFsConnect': False
                },
                'ReservedMemory': []
            }
        }
        
        # Customize for computer type
        if computer_type == 'AMD_PC':
            # AMD-specific settings
            config['Kernel']['Quirks']['AppleXcpmCfgLock'] = True
            config['PlatformInfo']['Generic']['SystemProductName'] = 'iMacPro1,1'
        
        return config
    
    def add_kexts_to_config(self, config, kext_files):
        """Add kext entries to config"""
        for kext_name, kext_path in kext_files.items():
            kext_entry = {
                'Arch': 'x86_64',
                'BundlePath': kext_name,
                'Comment': f'Auto-injected: {kext_name}',
                'Enabled': True,
                'ExecutablePath': self.get_kext_executable(kext_path),
                'MaxKernel': '',
                'MinKernel': '',
                'PlistPath': 'Contents/Info.plist'
            }
            config['Kernel']['Add'].append(kext_entry)
        
        return config
    
    def get_kext_executable(self, kext_path):
        """Get executable path from kext Info.plist"""
        info_plist = kext_path / "Contents" / "Info.plist"
        if info_plist.exists():
            try:
                with open(info_plist, 'rb') as f:
                    plist = plistlib.load(f)
                    executable = plist.get('CFBundleExecutable', '')
                    if executable:
                        return f'Contents/MacOS/{executable}'
            except:
                pass
        return ''
    
    def generate_opencore_config(self, computer_type):
        """Main function to generate complete OpenCore config"""
        print("=" * 60)
        print("🍎 OpenCore Configuration Generator")
        print("=" * 60)
        
        print(f"\n💻 Computer Type: {computer_type}")
        
        # Get required kexts
        required = self.get_required_kexts(computer_type)
        print(f"\n📋 Required Kexts: {len(required)}")
        
        # Find kexts in archive
        found = self.find_kexts_in_archive(required)
        print(f"✅ Found in Archive: {len(found)}/{len(required)}")
        
        missing = set(required) - set(found.keys())
        if missing:
            print(f"⚠️  Missing: {', '.join(missing)}")
        
        # Generate base config
        print(f"\n🔧 Generating config.plist...")
        config = self.generate_base_config(computer_type)
        
        # Add kexts
        config = self.add_kexts_to_config(config, found)
        
        # Save config
        output_dir = self.base_dir / "GeneratedEFI" / "EFI" / "OC"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        config_file = output_dir / "config.plist"
        with open(config_file, 'wb') as f:
            plistlib.dump(config, f)
        
        print(f"✅ Config saved: {config_file}")
        
        # Copy kexts to OC folder
        kexts_dir = output_dir / "Kexts"
        kexts_dir.mkdir(exist_ok=True)
        
        print(f"\n📦 Copying kexts to EFI...")
        for kext_name, kext_path in found.items():
            dest = kexts_dir / kext_name
            if dest.exists():
                shutil.rmtree(dest)
            shutil.copytree(kext_path, dest)
            print(f"   ✅ {kext_name}")
        
        print(f"\n🎉 OpenCore config generated successfully!")
        print(f"   Config: {config_file}")
        print(f"   Kexts: {kexts_dir}")
        
        return config_file

def main():
    """Test the injector"""
    injector = OpenCoreInjector()
    
    # Detect computer type (would come from wrapper)
    computer_type = injector.hardware_profile.get('platform', 'INTEL_PC')
    if computer_type == 'Intel':
        computer_type = 'INTEL_PC'
    elif computer_type == 'AMD':
        computer_type = 'AMD_PC'
    
    # Generate config
    injector.generate_opencore_config(computer_type)

if __name__ == "__main__":
    main()
