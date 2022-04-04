#!/bin/sh

# Introduction
echo "Nice to meet you Administrator :) I see you are setting up another API Server! That's nice! Let's get started, shall we! "

# Ask for administrator password to run script
echo " Ask for the administrator/root password for the duration of this script"
sudo -v

###############################################################################
# Hostname & IP Address                                                       #
###############################################################################

# Change Hostname of Server if not previously done, and set variables for HOST & HOSTNAME
printf "What would you like to set the Hostname as for this server? example: i13 "
read -r HOST
if [ -z "$HOST" ]; then
  printf "HOST is empty" >&2
  exit 1
fi
while true; do
  printf "Is that the correct Hostname? $HOST [y/n]: "
  read -r yn
 case $yn in
       [Yy]* ) #proceed with setup; 
       sudo echo "$HOST" 
       sudo scutil --set HostName "$HOST".api.omnifocus.com
       export "HOSTNAME"
       sudo scutil --set ComputerName "$HOSTNAME"
       sudo scutil --set HostName "$HOSTNAME"
       sudo scutil --set LocalHostName "$HOSTNAME"
       sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOSTNAME"
       break;;
        [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
done

# Get Server IP Address; network config for en0
ipconfig getifaddr en0
# Set IP Address as variable
IP="$(ipconfig getifaddr en0)"
export "IP"

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
# Never go into computer sleep mode
sudo systemsetup -setcomputersleep Off > /dev/null

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

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
# Install Packages                                                            #
###############################################################################

echo "Now Installing Packages"

echo "Installing Xcode tools"
sudo xcode-select --install

echo "Installing Rosetta 2"
/usr/sbin/softwareupdate --install-rosetta --agree-to-license

echo "Installing Omni LaunchdHelpers"
curl -u ansible:94udDnIRloP8 --digest -O https://omnistaging.omnigroup.com/omnifocus-web-instancehelpers-production/releases/OmniFocusInstanceManager-v1.8.5-5b2d9e0761-Test.pkg
sudo /usr/sbin/installer -pkg /Users/Administrator/OmniFocusInstanceManager-v1.8.5-5b2d9e0761-Test.pkg -target /

echo "Installing nginx"
curl -O https://files.omnigroup.com/misc/offtwapi/nginx-1.21.6.mpkg
sudo /usr/sbin/installer -allowUntrusted -pkg /Users/Administrator/nginx-1.21.6.mpkg -target /

echo "Installing socat"
curl -O https://files.omnigroup.com/misc/offtwapi/socat-1.7.4.1_1.mpkg
sudo /usr/sbin/installer -allowUntrusted -pkg /Users/Administrator/socat-1.7.4.1_1.mpkg -target /

echo "Installing acme.sh"
export HOME='/var/root'
sudo echo $HOME
curl https://get.acme.sh | sh -s email=rangers@omnigroup.com

if [ -d "/usr/local/var" ] 
then
    echo "Directory /usr/local/var exists." 
else
    echo "Error: Directory /usr/local/var does not exist. Will create the directory now"
    mkdir -p /usr/local/var 
fi

echo "Installing metricbeat"
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.1.0-darwin-x86_64.tar.gz
tar xzvf metricbeat-8.1.0-darwin-x86_64.tar.gz
mv ./metricbeat-8.1.0-darwin-x86_64 ./metricbeat
sudo mv ./metricbeat /usr/local/var/metricbeat

echo " Installing filebeat"
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.1.0-darwin-x86_64.tar.gz
tar xzvf filebeat-8.1.0-darwin-x86_64.tar.gz
mv ./filebeat-8.1.0-darwin-x86_64 ./filebeat
sudo mv ./filebeat /usr/local/var/filebeat


###############################################################################
# Scripts                                                                     #
###############################################################################

echo "Now managing scripts"
cd /Users/Administrator/scripts/
sudo mv /Users/adminstrator/scripts/start_pfctl.sh /usr/local/bin/start_pfctl.sh
sudo chmod 755 /usr/local/bin/start_pfctl.sh
sudo mv /Users/adminstrator/scripts/start_oslog_shipping /usr/local/bin/start_oslog_shipping.sh
sudo chmod 755 /usr/local/bin/start_oslog_shipping.sh
sudo mv /Users/adminstrator/scripts/unlockdata.sh /usr/local/bin/unlockdata.sh
sudo chmod 755 /usr/local/bin/unlockdata.sh
cd /Users/Administrator/

###############################################################################
# Acme.sh                                                                     #
###############################################################################

echo "Now issuing acme.sh cert and setting the keys"

# Issue acme.sh cert for the specific server
export HOME='/var/root'
cd /var/root/.acme.sh
sudo /var/root/.acme.sh/acme.sh --issue --standalone -d "$HOSTNAME"

# Set the keys for the acme.sh cert and reload
export HOME='/var/root'
sudo mkdir /etc/ssl/keys
sudo /var/root/.acme.sh/acme.sh --install-cert -d "$HOSTNAME" \
--certpath       /etc/ssl/certs/website.pem \
--key-file       /etc/ssl/keys/website.key  \
--fullchain-file /etc/ssl/certs/website.pem \
--reloadcmd     "launchctl unload /Library/LaunchDaemons/org.macports.nginx.plist && launchctl load /Library/LaunchDaemons/org.macports.nginx.plist"

###############################################################################
# Create Users & Home Directories                                             #
###############################################################################

echo "Now creating the nagios, offtwadmin and offtw groups"
# Create nagios/offtwadmin/offtw groups and set PrimaryGroupID
sudo dscl . -create /Groups/nagios
sudo dscl . -create /Groups/offtwadmin
sudo dscl . -create /Groups/offtw
dscl localhost -create /Local/Default/Groups/nagios PrimaryGroupID 502
dscl localhost -create /Local/Default/Groups/offtwadmin PrimaryGroupID 504
dscl localhost -create /Local/Default/Groups/offtw PrimaryGroupID 503

echo "Now creating the nagios user and setting up the nagios monitoring"
# Create nagios user
dscl localhost -create /Local/Default/Users/nagios
dscl localhost -create /Local/Default/Users/nagios UniqueID 503
dscl localhost -create /Local/Default/Users/nagios NFSHomeDirectory /Users/nagios
dscl localhost -create /Local/Default/Users/nagios UserShell /bin/zsh
dscl localhost -create /Local/Default/Users/nagios RealName "nagios"

mkdir -p /Users/nagios/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2hYT+X4TIRDiFGfXdkn3j+r23jspeHqxGnN1xnaBh5MlTzBmqIfgCLHxDCzgIDVKG0IXJFeSZPrvgitPFYv9heJ5wbgoZVIh7wIUxlgpjkVX3ldYCe/BaVbXxz950Y/noxZqZx8cvEJ8Kkjm36HwwOO7C0ItBvXSsnowr4dAMxScJ26nBT9HqHXI2DrNZHBIIsbGmFno997w25bo6FbhCPl5D0zUFN0TIABjAvebyCjachJ7Ll+dgcOdhkMXqD8al9iv5Qj5gAr/5ywNftEPaNGHRcjRuo2SQaTr42+RQ8gZa0Gxs4v8qGkcauHcG9OYLzXOBWncxwlVjs2/jb8Cgw== nagios@oversight.omnigroup.com" >> /Users/nagios/.ssh/authorized_keys
chmod -R g-w /Users/nagios
chmod 700 /Users/nagios/.ssh

echo "Now creating the offtwadmin and offtw-dolt users"

# Create offtwadmin and offtw-dolt users
sudo dscl . -create /Users/offtwadmin
sudo dscl . -create /Users/offtw-dolt
sudo dscl . -create /Users/offtwadmin NFSHomeDirectory /Users/offtwadmin
sudo dscl . -create /Users/offtwadmin UniqueID 504
sudo dscl . -create /Users/offtw-dolt UniqueID 505

mkdir -p /Users/offtwadmin/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8Ox31w/Mxby6LRiP7B8QkNDLBjgaIGxBSIdWB94llLjbXIeqSkNyHIiiv9QLbSpMhVshPyVk5wscGfxSYBylLRJGo2cH12fAEnYsDr1FsI4z9xw1TlJsrZqNQJC2Z6XsbGLFgrbULiDO765iylliumInNFVPxmdXoryXl6B5kEDrg9pFA5YQElAj5tNJGWzEvAmEac2d5CQGVgvgHTYSUq9iKeh1EOBuA4a1ir/esyoXGlXQUu5KyJ+OG2gl3PZRMxFNgbkKOztjd3EG1B88Gzh3f8lZFWiV8h1pixMPWNc7lcI9JQYK3QaA4tuAW+bjsds5FlHx/ct19S0DwDkxr mike@MikeD-MacBook.local" >> /Users/offtwadmin/.ssh/authorized_keys
echo "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABDYBfPAzs3MS0bI0SYkYzTz3q0030AyFWlLVPeVy677VCBe9fmp46QRSO71IzxHgq6ZG6DCOahta/Q0FSbiQu2cAEqDNGHnwnrB8+dFVgwx0Q1mrqsT062IHkQ6dEW7tNuiVmCqYEv2gg6nW2d0QaxoFhX5IaddBd+9vYZZ3oJSD4cXg== mike@MikeD-MacBook.local" >> /Users/offtwadmin/.ssh/authorized_keys
chmod -R g-w /Users/offtwadmin
chmod 700 /Users/offtwadmin/.ssh

echo "Now adding users to groups"
# Add users to groups
sudo dscl . create /Groups/offtwadmin GroupMembership offtwadmin _www
sudo dscl . create /Groups/offtw GroupMembership offtw-dolt
sudo dscl . create /Groups/nagios GroupMembership nagios

###############################################################################
# Conf and LaunchDaemons files                                                #
###############################################################################

echo "Now adding conf files"
sudo mkdir /usr/local/var/metricbeat/
sudo mkdir /usr/local/var/filebeat/
sudo mv /Users/administrator/confs/metricbeat.yml /usr/local/var/metricbeat/metricbeat.yml
sudo mv /Users/administrator/confs/filebeat.yml /usr/local/var/filebeat/filebeat.yml
sudo mv /Users/administrator/confs/pf.conf /etc/pf.conf
sudo mv /Users/administrator/confs/nginx.conf /etc/
sudo mkdir /usr/local/bin
sudo mkdir /usr/local/sbin
sudo ln -s /opt/local/bin/socat /usr/local/bin/
sudo ln -s /opt/local/sbin/nginx /usr/local/sbin/

echo "Now adding launchd files"
sudo mv /Users/Administrator/launchd/*.plist /Library/LaunchDaemons/

# Print commands needed for use on the offtw-coordinator
echo "Printing commands needed for use on the offtw-coordinator"

cat /etc/ssh/*.pub | grep -F -v 'ssh-dss' | perl -nae 'use MIME::Base64; split; $h = unpack("H*", decode_base64($F[1])); print "insert into host_key values (\x27'"$HOSTNAME"'\x27, X\x27$h\x27);\n";' | tee ~/register_with_coordinator.txt

echo "INSERT INTO '$HOST' VALUES('$HOST','$HOSTNAME','$IP',NULL,'Some Location');"
echo "$HOST"
echo "$HOSTNAME"
echo "$IP"

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
sudo newfs_apfs -i -E -v "Data" -S "KtGK3xGTnSBpv3nELHZhJ0FobUwfoz" -A disk3

# Decrypt and mount the new volume
datadisk=$(diskutil list | grep "APFS Volume.*Data" | grep -o 'disk.*' | tail -1)
  diskutil apfs unlockVolume $datadisk -passphrase $1

echo "Now creating the apps and containers directories in /Volumes/Data"
# Create apps and containers directories in /Volumes/Data
cd /Volumes/Data
sudo mkdir apps
sudo mkdir containers

echo "Now setting permissions for users and groups for the apps and containers directories"
# Set permissions for apps/containers directories for users: offtwadmin and offtw-dolt
sudo chown root:offtwadmin /Volumes/Data/apps
sudo chmod 771 /Volumes/Data/apps
sudo chown root:offtw /Volumes/Data/containers
sudo chmod 710 /Volumes/Data/containers
sudo chmod +a "group:offtwadmin allow list,search" /Volumes/Data/containers

###############################################################################
# Final Verification                                                          #
###############################################################################

echo "Final verification"
# View system info
sw_vers
uname -a
uptime
mount
echo "$PATH"
echo "Listing Users"
dscl . -list /Users | grep -v '^_'

# Reboot the system
echo "Well that was fun, wasn't it? I hope everything worked as it should :) "
echo "Note that some of these changes require a logout/restart to take effect."
exec "$SHELL"
