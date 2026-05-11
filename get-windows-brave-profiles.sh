#!/bin/bash
# Run this on WSL to extract Brave profile directory→name mappings from Windows.
# Output is saved to windows-brave-profiles.txt in the same directory as this script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_STATE="/mnt/c/Users/cavanaug/AppData/Local/BraveSoftware/Brave-Browser/User Data/Local State"

echo "Reading: $LOCAL_STATE"

python3 -c "
import json, sys

with open(sys.argv[1], encoding='utf-8') as f:
    d = json.load(f)

profiles = d.get('profile', {}).get('info_cache', {})
print(f'Found {len(profiles)} profile(s):\n')
print(f'  {\"Directory\":<20}  {\"Display Name\"}')
print(f'  {\"-\"*20}  {\"-\"*30}')
for dir_name, info in sorted(profiles.items()):
    print(f'  {dir_name:<20}  {info.get(\"name\", \"?\")}')
" "$LOCAL_STATE" | tee "$SCRIPT_DIR/windows-brave-profiles.txt"

echo ""
echo "Output saved to: $SCRIPT_DIR/windows-brave-profiles.txt"
