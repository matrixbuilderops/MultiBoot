#!/bin/bash
sudo mount /dev/sde1 /mnt/efi_fix
cd /mnt/efi_fix/EFI/OC

python3 << 'PY'
import plistlib

with open('config.plist', 'rb') as f:
    config = plistlib.load(f)

config['Misc']['Security']['SecureBootModel'] = 'Disabled'
config['Misc']['Security']['Vault'] = 'Optional'
if 'BlessOverride' not in config['Misc']:
    config['Misc']['BlessOverride'] = []

with open('config.plist', 'wb') as f:
    plistlib.dump(config, f)

print("✅ OPENCORE CONFIG FIXED!")
PY

sudo sync
sudo umount /mnt/efi_fix
