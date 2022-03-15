#!/bin/bash

# Introduction
echo "Nice to meet you Administrator :) I see you are setting up another API Server! That's nice! Let's get started, shall we! "
echo "What would you like to name this api server? Our previous api servers use the naming scheme i##.api.omnifocus.com"
read varname
HOSTNAME=varname".api.omnifocus.com"
TIMEZONE="America/Seattle" # 'systemsetup -listtimezones'

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

###############################################################################
# Install Packages                                                            #
###############################################################################

echo "Installing nginx"
sudo installer -pkg /Users/administrator/Desktop/nginx-1.21.6.pkg -target /

echo "Installing socat"
sudo installer -pkg /Users/administrator/Desktop/socat-1.7.4.3.pkg -target /

echo "Installing acme.sh"
systemctl reload nginx.service
curl https://get.acme.sh | sh -s email=rangers@omnigroup.com
echo "Please configure nginx so that Acme.sh can pull the proper certificates into nginx"

echo "Installing metricbeat"
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.1.0-darwin-x86_64.tar.gz
tar xzvf metricbeat-8.1.0-darwin-x86_64.tar.gz

echo " Installing filebeat"
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.1.0-darwin-x86_64.tar.gz
tar xzvf filebeat-8.1.0-darwin-x86_64.tar.gz

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

# Setup acme.sh
# Set the notification level:  Default value is 2.
#0: disabled, no notification will be sent.
#1: send notification only when there is an error. No news is good news.
#2: send notification when a cert is successfully renewed, or there is an error
#3: send notification when a cert is skipped, renewed, or error. You will receive notification every night with this level.
acme.sh --set-notify  [--notify-hook mail]
acme.sh --set-notify  [--notify-level 2]
acme.sh --set-notify  [--notify-mode 0]
export MAIL_FROM="rangers@omnigroup.com" # or "Xxx Xxx <xxx@xxx.com>", currently works only with sendmail
export MAIL_TO="rangers@omnigroup.com"   # your account e-mail will be used as default if available
acme.sh --issue --standalone -d i13.api.omnifocus.com

# Look for suspicious and self-signed SSL certificates
tcpdump -U -s 1500 -A '(tcp[((tcp[12:1] & 0xf0) >> 2)+5:1] = 0x01) and (tcp[((12:1] & 0xf0) >> 2) :1] = 0x16)'
# Grab PID of tcpdump
pid=$(ps -e | pgrep tcpdump)  
echo $pid 
# Interrupt tcpdump
sleep 5
kill -2 $pid

# Use nmap to listen for scanning threats
nmap -p 80-443 192.168.0.1

# Show IP address, hostname, OS version when clicking the clock in the login window
#echo " Show IP address, hostname, OS version when clicking the clock in the login window"
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Get Server IP Address; network config for ethO
ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo `ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`

#firewall-cmd  --permanent --add-port 8000/tcp     # plain-HTTP version of service
#firewall-cmd  --permanent --add-port 2022/tcp     # encrypted debug/inspection manhole
#firewall-cmd  --permanent --add-forward-port=port=443:proto=tcp:toport=4433
#firewall-cmd  --reload

#OS log shipping
log stream --info | /usr/local/bin/socat -dddd STDIN TCP4:search1.sync.omnigroup.com:5051,interval=4,reuseaddr,forever

# Start pf
pfctl -e -f /etc/pf.conf

# View system info
uname -a
uptime
timedatectl
mount
echo $PATH
cat /root/.ssh/authorized_keys
ps -aux

# Reboot the system
echo "Well that was fun, wasn't it? I hope everything worked as it should :) "
echo "Done. Note that some of these changes require a logout/restart to take effect."
exec "$SHELL"
