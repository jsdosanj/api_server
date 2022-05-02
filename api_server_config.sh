#!/bin/sh

# Introduction
echo "Nice to meet you Administrator :) I see you are setting up another API Server! That's nice! Let's get started, shall we! "

# Ask for administrator password to run script
echo " Ask for the administrator/root password for the duration of this script"
sudo -v

###############################################################################
# Hostname                                                                    #
###############################################################################

# Change Hostname of Server if not previously done
printf "What would you like to set the Hostname as for this server? "
read -r HOSTNAME
if [ -z "$HOSTNAME" ]; then
  printf "HOSTNAME is empty" >&2
  exit 1
fi
while true; do
  read -r "Is that the correct Hostname? $HOSTNAME" yn
 case $yn in
       [Yy]* ) proceed with setup; 
	   sudo echo "$HOSTNAME" 
	   sudo scutil --set ComputerName "$HOSTNAME"
	   sudo scutil --set HostName "$HOSTNAME"
	   sudo scutil --set LocalHostName "$HOSTNAME"
	   sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOSTNAME"
	   break;;
        [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
done

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

echo "Now running Activity Monitor Commands"

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

echo "Now Installing Packages"

echo "Installing Omni LaunchdHelpers"
curl -u ansible:94udDnIRloP8 --digest -O https://omnistaging.omnigroup.com/omnifocus-web-instancehelpers-production/releases/OmniFocusInstanceManager-v1.8.5-5b2d9e0761-Test.pkg

echo "Installing nginx"
sudo installer -pkg /Users/administrator/Desktop/nginx-1.21.6.pkg -target /

echo "Installing socat"
sudo installer -pkg /Users/administrator/Desktop/socat-1.7.4.3.pkg -target /

echo "Installing acme.sh"
launchctl reload nginx.service
export HOME='/var/root'
sudo echo $HOME
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

echo "Now creating ssh key"
# To create public-ssh key
ssh-keygen -t rsa

# To view public-ssh key
cat ~/.ssh/id_rsa.pub

###############################################################################
# Acme.sh                                                                     #
###############################################################################

echo "Now issuing acme.sh cert and setting the keys"

# Issue acme.sh cert for the specific server
sudo nginx -s stop && sudo nginx
sudo echo $HOME
sudo acme.sh --issue --standalone -d "$HOSTNAME"

# Set the keys for the acme.sh cert and reload
sudo echo $HOME
sudo /var/root/.acme.sh/acme.sh --install-cert -d "$HOSTNAME" \
--key-file       /etc/ssl/keys/website.key  \
--fullchain-file /etc/ssl/certs/website.pem \
--reloadcmd     "launchctl unload /Library/LaunchDaemons/org.macports.nginx.plist && launchctl load /Library/LaunchDaemons/org.macports.nginx.plist"

###############################################################################
# Create Users & Home Directories                                             #
###############################################################################

echo "Now creating the nagios user and setting up the nagios monitoring"

# Create nagios user
dscl localhost -create /Local/Default/Users/nagios
dscl localhost -create /Local/Default/Users/nagios UniqueID 503
dscl localhost -create /Local/Default/Users/nagios PrimaryGroupID 20
dscl localhost -create /Local/Default/Users/nagios NFSHomeDirectory /Users/nagios
dscl localhost -create /Local/Default/Users/nagios UserShell /bin/zsh
dscl localhost -create /Local/Default/Users/nagios RealName "nagios"

mkdir -p /Users/nagios/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2hYT+X4TIRDiFGfXdkn3j+r23jspeHqxGnN1xnaBh5MlTzBmqIfgCLHxDCzgIDVKG0IXJFeSZPrvgitPFYv9heJ5wbgoZVIh7wIUxlgpjkVX3ldYCe/BaVbXxz950Y/noxZqZx8cvEJ8Kkjm36HwwOO7C0ItBvXSsnowr4dAMxScJ26nBT9HqHXI2DrNZHBIIsbGmFno997w25bo6FbhCPl5D0zUFN0TIABjAvebyCjachJ7Ll+dgcOdhkMXqD8al9iv5Qj5gAr/5ywNftEPaNGHRcjRuo2SQaTr42+RQ8gZa0Gxs4v8qGkcauHcG9OYLzXOBWncxwlVjs2/jb8Cgw== nagios@oversight.omnigroup.com" >> /Users/nagios/.ssh/authorized_keys
chown -R nagios:20 /Users/nagios
chmod -R g-w /Users/nagios
chmod 700 /Users/nagios/.ssh

echo "Now creating the offtwadmin and offtw-dolt users"

# Create offtwadmin and offtw-dolt users
sudo dscl . -create /Users/offtwadmin
sudo dscl . -create /Users/offtw-dolt
sudo dscl . -create /Users/offtwadmin NFSHomeDirectory /Local/Users/offtwadmin
#sudo dscl . -create /Users/offtw-dolt NFSHomeDirectory /Local/Users/offtw-dolt
sudo dscl . -create /Users/offtwadmin UniqueID 504
sudo dscl . -create /Users/offtwadmin PrimaryGroupID 504
sudo dscl . -create /Users/offtw-dolt UniqueID 505
sudo dscl . -create /Users/offtw-dolt PrimaryGroupID 503

echo "Now created the nagios, offtwadmin and offtw groups"
# Create nagios/offtwadmin/offtw groups
sudo dscl . -create /Groups/nagios
sudo dscl . -create /Groups/offtwadmin
sudo dscl . -create /Groups/offtw

echo "Now adding users to groups"
# Add users to groups
sudo dscl . -append /Groups/offtwadmin GroupMembership offtwadmin
sudo dscl . -append /Groups/offtw-dolt GroupMembership offtw
sudo dscl . -append /Groups/nagios GroupMembership nagios

###############################################################################
# /Volumes/Data APFS Encrytion & Permissions.                                 #
###############################################################################

# Permissions for containers 		|	Permissions for apps
# system: read & write			| 	system: read & write
# offtwadmin: custom			| 	offtwadmin: read & write
# everyone: read only			| 	everyone: no access
# offtw-dolt: read & write

echo "Now apfs encrypting /Volumes/Data"
# Encrypt /Volumes/Data with APFS encryption
echo "Creating an apfs encrypted volume in /Volumes/Data"
sudo newfs_apfs -i -E -v "Data" -A disk3
#data_volume_passphrase: KtGK3xGTnSBpv3nELHZhJ0FobUwfoz

echo "Now creating the apps and containers directories in /Volumes/Data"
# Create apps and containers directories in /Volumes/Data
cd /Volumes/Data || exit
mkdir apps
mkdir containers

echo "Now setting permissions for users and groups for the apps and containers directories"
# Set permissions for apps/containers directories for users: offtwadmin and offtw-dolt
chmod +a "everyone no access" /Volumes/Data/apps
chmod +a "system allow read,write" /Volumes/Data/apps
chmod +a "offtwadmin allow read,write,delete,add_file,add_subdirectory,file_inherit,directory_inherit" /Volumes/Data/apps
chmod +a "offtwadmin allow read,write,delete,add_file,add_subdirectory,file_inherit,directory_inherit" /Volumes/Data/containers
chmod +a "offtw-dolt allow read,write,delete,add_file,add_subdirectory,file_inherit,directory_inherit" /Volumes/Data/containers
chmod +a "everyone allow read" /Volumes/Data/containers
chmod +a "system allow read" /Volumes/Data/containers

###############################################################################
# Create mini scripts                                                         #
###############################################################################
echo "Now creating mini scripts"

touch ~/usr/local/bin/start_pfctl.sh
printf '#!/bin/bash \n # Wait 30 seconds\n sleep 30\n # Start pf\n pfctl -e -f /etc/pf.conf' >> ~/usr/local/bin/start_pfctl.sh
sudo chmod 755 start_pfctl.sh

touch ~/usr/local/bin/start_oslog_shipping.sh
printf '#!/bin/bash\n log stream --info | /usr/local/bin/socat -dddd STDIN TCP4:{{ elasticsearch_server }}:{{ elasticsearch_port }},interval=4,reuseaddr,forever' >> ~/usr/local/bin/start_oslog_shipping.sh
sudo chmod 755 start_oslog_shipping.sh

###############################################################################
# Final Verification                                                          #
###############################################################################

echo "Final verification"
# Get Server IP Address; network config for en0
ipconfig getifaddr en0

# View system info
sw_vers
uname -a
uptime
mount
echo "$PATH"

# Reboot the system
echo "Well that was fun, wasn't it? I hope everything worked as it should :) "
echo "Note that some of these changes require a logout/restart to take effect."
exec "$SHELL"