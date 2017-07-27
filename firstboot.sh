#!/bin/bash
# RFSD-Config-Script-OSX-10.10DP8_v7
# From Daniel Rheiner Edited BB 7/26/17
# Date of Compile: 2/13/2014
# Version 1
# OS X 10.10 Beta

# *** Items are Disabled in this script for BETA Testing - undone - TF ***
# Remove Applications, SMB 2&3 Disable

# $3 = Username when executed as a login or logout policy

# Define variables
awk="/usr/bin/awk"
consoleuser=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')
#cp="/bin/cp"
dscl="/usr/bin/dscl"
#dsconfigad="/usr/sbin/dsconfigad"
dseditgroup="/usr/sbin/dseditgroup"
echo="/bin/echo"
find="/usr/bin/find"
grep="/usr/bin/grep"
#ipconfig="/usr/sbin/ipconfig"
kickstart="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
killall="/usr/bin/killall"
launchctl="/bin/launchctl"
ln="/bin/ln"
#logdir="/Library/Logs"
mkdir="/bin/mkdir"
mv="/bin/mv"
networksetup="/usr/sbin/networksetup"
#OS=$(/usr/bin/defaults read /System/Library/CoreServices/SystemVersion ProductVersion | /usr/bin/awk '{print substr($1,1,4)}')
perl="/usr/bin/perl"
sleep="/bin/sleep"
systemsetup="/usr/sbin/systemsetup"
#perl="/usr/bin/perl"
#plistbuddy="/usr/libexec/PlistBuddy"
rm="/bin/rm"
touch="/usr/bin/touch"
#uuid=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/grep -i "UUID" | /usr/bin/cut -c27-62)
scutil="/usr/sbin/scutil"


#####################################################
# # 
# Network, VPN, Active Directory & Time Services #
# #
#####################################################

#killall cfprefsd
#sudo killall cupsd
#sudo launchctl unload /System/Library/LaunchDaemons/org.cups.cupsd.plist
#sudo launchctl load /System/Library/LaunchDaemons/org.cups.cupsd.plist
#sudo update_dyld_shared_cache -root /

# Refresh Network Adapters
/usr/sbin/networksetup -detectnewhardware

#Default search domains
SearchDomains=rfsd.k12.co.us rfsd.local

#Time Zone
TimeZone=America/Denver

# Set the time zone
/usr/sbin/systemsetup -settimezone $TimeZone

# Primary Time server
TimeServer1=time.apple.com

# Secondary Time server
TimeServer2=0.pool.ntp.org

# Tertiary Time Server
TimeServer3=1.pool.ntp.org

# Activate the primary time server. Set the primary network server with systemsetup
/usr/sbin/systemsetup -setnetworktimeserver $TimeServer1

# Add the secondary time server
echo "server $TimeServer2" >> /etc/ntp.conf

# Add the tertiary time server
echo "server $TimeServer3" >> /etc/ntp.conf

# Enables the OS X to set its clock using the network time server
/usr/sbin/systemsetup -setusingnetworktime on

# Turns off SMB2 & SMB3 network protocol and forces OS X 10.10 to use SMB1 for legacy Netapp servers
# echo "[default]" >> ~/Library/Preferences/nsmb.conf; echo "smb_neg=smb1_only" >> ~/Library/Preferences/nsmb.conf

# Turn off DS_Store file creation on network volumes
#defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores true

# Disable external accounts (i.e. accounts stored on drives other than the boot drive.)
#defaults write /Library/Preferences/com.apple.loginwindow EnableExternalAccounts -bool false

# Clear text passwords in AFP
#/usr/bin/defaults write com.apple.AppleShareClient "afp_cleartext_allow" 1

# Bypass updating Managed Settings Message
defaults write /Library/Preferences/com.apple.mdmclient BypassPreLoginCheck -bool YES

# Disable the save window state at logout
/usr/bin/defaults write com.apple.loginwindow 'TALLogoutSavesState' -bool false

# Remove the loginwindow delay by loading the com.apple.loginwindow
#launchctl load /System/Library/LaunchDaemons/com.apple.loginwindow.plist

# Set Shutdown and Logoff timers to 1 second (No Delay)
sudo defaults write /System/Library/LaunchDaemons/com.apple.coreservices.appleevents ExitTimeOut -int 1
sudo defaults write /System/Library/LaunchDaemons/com.apple.securityd ExitTimeOut -int 1
sudo defaults write /System/Library/LaunchDaemons/com.apple.mDNSResponder ExitTimeOut -int 1
sudo defaults write /System/Library/LaunchDaemons/com.apple.diskarbitrationd ExitTimeOut -int 1

# Disable default file sharing for guest
defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false

# Enable ARD, Remote Management, and Remote Login (SSH) - 1. Removes Administrators Group from Remote login, 2 & 3. Creates xxxxxxxxx Membership, 4 & 5. Adds xxxxxxxxx User to Remotelogin then activates.
sudo dseditgroup -o edit -d admin -t group com.apple.access_ssh
#sudo dscl . append /Groups/com.apple.access_ssh user macadmin
sudo dscl . append /Groups/com.apple.access_ssh user techies
sudo dscl . append /Groups/com.apple.access_ssh GroupMembership admin
#sudo dscl . append /Groups/com.apple.access_ssh groupmembers `dscl . read /Users/macadmin GeneratedUID | cut -d " " -f 2`
sudo dscl . append /Groups/com.apple.access_ssh groupmembers `dscl . read /Users/techies GeneratedUID | cut -d " " -f 2`
sudo systemsetup -setremotelogin on
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -specifiedUsers
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -users techies,macadmin -access -on -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -activate -restart -console


#####################################################
# # 
# Baseline initial System Setup #
# #
#####################################################


# Rename boot drive to Macintosh HD
#diskutil rename / "Macintosh HD"

# set bonjour, host and sharing names based on patch level and en0 (ethernet) mac address
LAST6_ENETADDY=`ifconfig en0 | grep ether | awk '{print $2}' | sed 's/://g' | cut -c 7-12 | tr [:lower:] [:upper:]`
PATCHLVL=`/usr/bin/defaults read "/System/Library/CoreServices/SystemVersion" ProductVersion | sed 's/[.]/-/g'`
$scutil --set LocalHostName "RFSD$LAST6_ENETADDY-rename"
$scutil --set ComputerName "RFSD$LAST6_ENETADDY-rename"
$scutil --set HostName "RFSD$LAST6_ENETADDY-rename"
RENAMED=`$scutil --get HostName`

#Allow users to set initial DVD Region
#security authorizationdb read system.device.dvd.setregion.initial > /tmp/system.device.dvd.setregion.initial.plist
#/usr/libexec/PlistBuddy -c "Set class allow" /tmp/system.device.dvd.setregion.initial.plist
#security authorizationdb write system.device.dvd.setregion.initial < /tmp/system.device.dvd.setregion.initial.plist

# Disable Hibernation Services
sudo pmset -a hibernatemode 0

# Disable OS X OS Prerelease downloads for all users 
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AllowPreReleaseInstallation -bool false

# Set the login window to name and password
#defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

# Enable Fast User Switching option
defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool 'YES'

# Disable iCloud & Apple Assistant Popup for new user creation
for USER_TEMPLATE in "/System/Library/User Template"/*
do
defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion 10.10
done
mv /System/Library/CoreServices/Setup\ Assistant.app/Contents/SharedSupport/MiniLauncher /System/Library/CoreServices/Setup\ Assistant.app/Contents/SharedSupport/MiniLauncher.backup
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.finder.plist" ProhibitGoToiDisk -bool YES

# Remove Setup LaunchDaemon item
srm /Library/LaunchDaemons/com.company.initialsetup.plist

# Disable Time Machine's & pop-up message whenever an external drive is plugged in
for USER_TEMPLATE in "/System/Library/User Template"/*
do
defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
done
defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
defaults write /Library/Preferences/com.apple.TimeMachine AutoBackup -boolean NO

# Disable Time Machine snapshots on local disk
sudo tmutil disablelocal

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Turn off Automatic updates
sudo softwareupdate --schedule off

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Give all end-users permissions full access to "Print & Scan, Network, Time" Preference Pane
security authorizationdb write system.preferences allow
security authorizationdb write system.preferences.datetime allow
security authorizationdb write system.preferences.network allow
security authorizationdb write system.services.systemconfiguration.network allow
security authorizationdb write system.preferences.printing allow
/usr/bin/security authorizationdb write system.print.operator allow
/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group _lpadmin
/usr/sbin/dseditgroup -o edit -n /Local/Default -a 'Domain Users' -t group lpadmin

# See next preferred pmset settings… these, from original script are commented out. Power Settings for all Users (Display Sleep, Workstation Sleep, Wake for network access) (Pmset -a = All Power modes | Pmset -c = A/C Power | Pmset -b = Battery Power)
#pmset -a halfdim 1 gpuswitch 2 hibernatemode 0 lidwake 1 sms 1
#pmset -c sleep 180 displaysleep 30 disksleep 0 womp 1 networkoversleep 0 
#pmset -b sleep 20 displaysleep 15 disksleep 10 

# Detects if this Mac is a laptop or not by checking the model ID for the word "Book" in the name.

is_laptop=`/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book"`
if [ -n “$is_laptop” ]; then
pmset -b sleep 30 disksleep 10 displaysleep 15 halfdim 1
pmset -c sleep 0 disksleep 0 displaysleep 30 halfdim 1
else
pmset sleep 0 disksleep 0 displaysleep 30 halfdim 1
fi

# Automatically illuminate built-in MacBook keyboard in low light and turn off in idle after 5 minutes
defaults write com.apple.BezelServices kDim -bool true
defaults write com.apple.BezelServices kDimTime -int 300

# Sets System Volume level to 50% 
#osascript -e 'set volume output volume 50'

# Hide the following applications: Game Center, Boot Camp
#sudo chflags hidden /Applications/Game\ Center.app/
# sudo chflags hidden /Applications/Time\ Machine.app/
#sudo chflags hidden /Applications/Utilities/Boot\ Camp\ Assistant.app/

# Make a shortcut links to Network Utility, Directory Utility, Screen Sharing, Raid Utility, and Archive Utility under "Utilities" Folder
#ln -s /System/Library/CoreServices/Applications/Network\ Utility.app /Applications/Utilities/Network\ Utility.app
#ln -s /System/Library/CoreServices/Applications/Directory\ Utility.app /Applications/Utilities/Directory\ Utility.app
#ln -s /System/Library/CoreServices/Applications/Screen\ Sharing.app /Applications/Utilities/Screen\ Sharing.app
#ln -s /System/Library/CoreServices/Applications/RAID\ Utility.app /Applications/Utilities/RAID\ Utility.app
#ln -s /System/Library/CoreServices/Applications/Archive\ Utility.app /Applications/Utilities/Archive\ Utility.app

# Set the ability to view additional system info at the Login window.
defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText “This computer is owned and managed by the Roaring Fork School District, and is intended for use by it’s employees, affiliates, and students only.“

# Turn SSH on
systemsetup -setremotelogin on

# Turn off Gatekeeper
spctl --master-disable

# Disable Gatekeeper's auto-rearm. Otherwise Gatekeeper
# will reactivate every 30 days. When it reactivates, it
# will be be set to "Mac App Store and identified developers"
/usr/bin/defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool false

# Set the RSA maximum key size to 32768 bits (32 kilobits) in
# /Library/Preferences/com.apple.security.plist to provide
# future-proofing against larger TLS certificate key sizes.
# For more information about this issue, please see the link below:
# http://blog.shiz.me/post/67305143330/8192-bit-rsa-keys-in-os-x
/usr/bin/defaults write /Library/Preferences/com.apple.security RSAMaxKeySize -int 32768

# Terminal command-line access warning
#/usr/bin/touch /etc/motd
#/bin/chmod 644 /etc/motd
#/bin/echo "" >> /etc/motd
#/bin/echo "This Apple Workstation, including all related equipment belongs to Roaring Fork School District. Unauthorized access to this workstation is forbidden and will be prosecuted by law. By accessing this system, you agree that your actions may be monitored if unauthorized usage is suspected." >> #/etc/motd
#/bin/echo "" >> /etc/motd


#####################################################
# # 
# End-User Profile Settings & System Setup #
# #
#####################################################


# Remove info files on all 
rm -R /System/Library/User\ Template/Non_localized/Downloads/About\ Downloads.lpdf
rm -R /System/Library/User\ Template/Non_localized/Documents/About\ Stacks.lpdf

# Show the ~/Library folder
sudo chflags nohidden /System/Library/User\ Template/English.lproj/Library/
/usr/bin/chflags nohidden $HOME/Library
sudo chflags nohidden /Users/xxxxxxxxx/Library

# Expand “General”, “Open with”, and “Sharing & Permissions” in File Information
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder FXInfoPanesExpanded -dict \
General -bool true \
OpenWith -bool true \
Privileges -bool true

# Disable “Application Downloaded from the internet” message
#sudo defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.LaunchServices LSQuarantine -bool NO
#defaults write com.apple.LaunchServices LSQuarantine -bool NO

# Disable “Application Downloaded from the internet” for the particular applications below
# sudo xattr -d -r com.apple.quarantine /Applications/Utilities/ADPassMon.app

# Disable the “Are you sure you want to open this application?” dialog
# defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.LaunchServices LSQuarantine -bool false

# Set Default Screen Saver (Display Computer Name)
mkdir /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "moduleName" -string "Message"
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "modulePath" -string "/System/Library/Screen Savers/FloatingMessage.saver"
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "idleTime" -int 600

# Enable Screensaver Password
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/ByHost/com.apple.screensaver.$MAC_UUID "askForPassword" -int 1
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.screensaver askForPassword -int 1
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.screensaver askForPasswordDelay -int 24

# Show "Mounted Server Shares, External and Internal Hard Disks" on the main Finder Desktop
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Expand the print window
defaults write /Library/Preferences/.GlobalPreferences PMPrintingExpandedStateForPrint2 -bool TRUE

# Configure Finder settings (List View, Show Status Bar, Show Path Bar)
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder "AlwaysOpenWindowsInListView" -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder ShowStatusBar -bool true
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.finder ShowPathbar -bool true

# Trackpad & Mouse: Map bottom right corner to right-click and secondary button for Mouse
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.mouse" MouseButtonMode -string TwoButton
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.driver.AppleHIDMouse" Button1 -integer 1
defaults write "/System/Library/User Template/English.lproj/Library/Preferences/com.apple.driver.AppleHIDMouse" Button2 -integer 2

# From Rich Trouton, created July 29, 2015:
# Set the ability to  view additional system info at the Login window
# The following will be reported when you click on the time display 
# (click on the time again to proceed to the next item):
#
# Computer name
# Version of OS X installed
# IP address
# This will remain visible for 60 seconds.

#/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Set whether you want to send diagnostic info back to
# Apple and/or third party app developers. If you want
# to send diagonostic data to Apple, set the following 
# value for the SUBMIT_DIAGNOSTIC_DATA_TO_APPLE value:
#
# SUBMIT_DIAGNOSTIC_DATA_TO_APPLE=TRUE
# 
# If you want to send data to third party app developers,
# set the following value for the
# SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS value:
#
# SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS=TRUE
# 
# By default, the values in this script are set to 
# send no diagnostic data: 

#SUBMIT_DIAGNOSTIC_DATA_TO_APPLE=FALSE
#SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS=FALSE

# Set the RSA maximum key size to 32768 bits (32 kilobits) in
# /Library/Preferences/com.apple.security.plist to provide
# future-proofing against larger TLS certificate key sizes.
#
# For more information about this issue, please see the link below:
# http://blog.shiz.me/post/67305143330/8192-bit-rsa-keys-in-os-x

/usr/bin/defaults write /Library/Preferences/com.apple.security RSAMaxKeySize -int 32768



#####################################################
# # 
# Cleanup & Maintenance #
# #
#####################################################


# Remove setup LaunchDaemon item
#/bin/rm -rf /Library/LaunchDaemons/com.rfschools.runFirstBoot.plist

# Hide /Opt/ Folder under root drive
chflags hidden /opt/
chflags hidden /private/
chflags hidden /usr/

# Delete Built-in Applications
# sudo rm -rf /Applications/GarageBand.app
# sudo rm -rf /Applications/iMovie.app
# sudo rm -rf /Applications/Keynote.app
# sudo rm -rf /Applications/Numbers.app
# sudo rm -rf /Applications/Pages.app

# Delete Temp User & Folders
#/usr/bin/dscl . -search /Users name Temp
#sudo /usr/bin/dscl . -delete "/Users/temp"
#rm -rf /Users/temp

# Repair Disk Permissions with Disk Utility command line 
# No longer works in Sierra
# diskutil repairPermissions /

# Run Built-in Unix Maintenance Scripts (Rotate & delete log files)
sudo periodic daily weekly monthly

# Purge System Log
/bin/rm -rf /var/log/system.log

exit 0
