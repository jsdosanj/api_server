#!/bin/bash
# Change Hostname of Server if not previously done
echo "$HOSTNAME"
read HOSTNAME
if [[ -z "$HOSTNAME" ]]; then
  echo "HOSTNAME is empty" >&2
  exit 1
fi
sudo echo "$HOSTNAME" 
sudo scutil --set ComputerName ""$HOSTNAME""
sudo scutil --set HostName "$HOSTNAME"
sudo scutil --set LocalHostName "$HOSTNAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOSTNAME"

##read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1


while true; do
  read -p "Is that the correct Hostname?" "$HOSTNAME" yn
 case $yn in
       [Yy]* ) proceed with setup; break;;
        [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
done