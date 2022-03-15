#!/bin/bash

# Introduction
echo "Nice to meet you Administrator :) "
HOSTNAME="i13.api.omnifocus.com"
TIMEZONE="America/Seattle" # 'systemsetup -listtimezones'
echo "Please manually install the 'dpkg' package to ensure that the script can install the other packages :) "

# Ask for administrator password to run script
echo " Ask for the administrator password for the duration of this script"
sudo -v

# Change Hostname of Server if not previously done
echo " Set computer name to $HOSTNAME (as done via System Preferences → Sharing)"
sudo scutil --set ComputerName $HOSTNAME
sudo scutil --set HostName $HOSTNAME
sudo scutil --set LocalHostName $HOSTNAME
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string $HOSTNAME

###############################################################################
# Safari & WebKit                                                             #
###############################################################################

echo "Now running Safari & Webkit commands"

# Show the full URL in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

echo "Now running Finder commands"

# Show Hidden files by default in Finder
echo " Finder: show hidden files by default"
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions in Finder
echo " Finder: show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

###############################################################################
# Terminal                                                                    #
###############################################################################

echo "Now running Terminal Commands"

# Enable Secure Keyboard Entry in Terminal.app
# See: https://security.stackexchange.com/a/47786/8918
defaults write com.apple.terminal SecureKeyboardEntry -bool true

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Disk Utility                                                                #
###############################################################################

echo "Now running Disk Utility commands"

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Unlock Data
if [ -d "/Volumes/Data" ]; then
  # Just return output
  echo "Disk already exists"
else
  # Unlock the disk
  datadisk=$(diskutil list | grep "APFS Volume Data" | grep -o 'disk.*')
  diskutil apfs unlockVolume $datadisk -passphrase $1
fi


###############################################################################
# Energy Saving                                                               #
###############################################################################

echo "Now running Energy Saving Commands"

# Hibernation mode
# 0: Disable hibernation (speeds up entering sleep mode)
# 3: Copy RAM to disk so the system state can still be restored in case of a
#    power failure.
#sudo pmset -a hibernatemode 0

# Never go into computer sleep mode
sudo systemsetup -setcomputersleep Off > /dev/null

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Remove the sleep image file to save disk space
#sudo rm /private/var/vm/sleepimage

###############################################################################
# Install Packages                                                            #
###############################################################################

#Install Packages
#dpkg --install acmetool-0.0.67_1.pkg
#dpkg --install filebeat-8.0.0.pkg
#dpkg --install grep-3.7.pkg
#dpkg --install kafka-3.1.0.pkg
#dpkg --install metricbeat-8.0.0.pkg
#dpkg --install monitoring-plugins-2.3.1.pkg #nagios plugins: https://www.monitoring-plugins.org/gi
#dpkg --install nginx-1.21.6.pkg
#dpkg --install socat-1.7.4.3.pkg
#dpkg --install zookeeper-3.7.0_1.pkg
#dpkg --install certbot-1.23.0.pkg

###############################################################################
# SSH, Firewall and Networking                                                #
###############################################################################

echo "Now running Networking Commands"

# Enable Screen Sharing
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

#Enable SSH
echo " Enable SSH "
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# To create public-ssh key
ssh-keygen -t rsa

# To view public-ssh key
cat ~/.ssh/id_rsa.pub

# Install Acme.sh
# https://www.rmedgar.com/blog/using-acme-sh-with-nginx/
# https://www.cyberciti.biz/faq/how-to-configure-nginx-with-free-lets-encrypt-ssl-certificate-on-debian-or-ubuntu-linux/
systemctl reload nginx.service
curl https://get.acme.sh | sh -s email=rangers@omnigroup.com
echo "Please configure nginx so that Acme.sh can pull the proper certificates into nginx"

# Show IP address, hostname, OS version when clicking the clock in the login window
#echo " Show IP address, hostname, OS version when clicking the clock in the login window"
#sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Get Server IP Address; network config for ethO
ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

#firewall-cmd  --permanent --add-port 8000/tcp     # plain-HTTP version of service
#firewall-cmd  --permanent --add-port 2022/tcp     # encrypted debug/inspection manhole
#firewall-cmd  --permanent --add-forward-port=port=443:proto=tcp:toport=4433
#firewall-cmd  --reload

#OS log shipping
log stream --info | /usr/local/bin/socat -dddd STDIN TCP4:search1.sync.omnigroup.com:5051,interval=4,reuseaddr,forever

# Start pf
pfctl -e -f /etc/pf.conf

# Reboot the system
echo "Done. Note that some of these changes require a logout/restart to take effect."
exec "$SHELL"