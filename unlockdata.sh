#!/bin/bash

if [ -d "/Volumes/Data" ]; then
  # Just return output
  echo "Disk already exists"
else
  # Unlock the disk
  datadisk=$(diskutil list | grep "APFS Volume Data" | grep -o 'disk.*')
  diskutil apfs unlockVolume $datadisk -passphrase $1
fi
