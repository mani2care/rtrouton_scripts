#!/bin/bash
 
available_free_space=$(df -g / | tail -1 | awk '{print $4}')
# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS
needed_free_space="$4"
os_name="$5"
insufficient_free_space_for_install_dialog="Your boot drive must have $needed_free_space gigabytes of free space available in order to install $os_name using Self Service. It has $available_free_space gigabytes available. If you need assistance with freeing up space, please contact the help desk."
adequate_free_space_for_install_dialog="$os_name may take up to 30 minutes to download and prepare for installation. Please be patient. Once the operating system has downloaded, this Mac will automatically restart to begin the installation process."
 
if [[ "$available_free_space" -lt "$needed_free_space" ]]; then
   jamf displayMessage -message "$insufficient_free_space_for_install_dialog"
fi
 
if [[ "$available_free_space" -ge "$needed_free_space" ]]; then
   echo "$available_free_space gigabytes found as free space on boot drive. Installing OS."

   # Checking for FileVault 2 encryption. If found, set FileVault 2's automatic login to
   # be disabled. 
   #
   # The reason to do this is that when upgrading a FileVault2 enabled Mac to 10.10, 
   # automatic login should  be disabled  when installing additional packages at first boot. 
   # If automatic login is not disabled, the additional packages will be skipped over.

   if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -eq 7 ) ]]; then
	ENCRYPTION=`diskutil cs list | grep -E "Encryption Type" | sed -e's/\|//' | awk '{print $3}'`
	   if [ "$ENCRYPTION" = "AES-XTS" ]; then
		   echo "FileVault 2 is enabled. Disabling FDEAutoLogin."
		   defaults write /Library/Preferences/com.apple.loginwindow DisableFDEAutoLogin -bool YES
	   else
		   echo "FileVault 2 is not enabled."
	   fi
   fi

   if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -ge 8 ) ]]; then
	   FDE=`fdesetup status | grep "Off"`
	   if [ "$FDE" = "" ]; then
		   echo "FileVault 2 is enabled. Disabling FDEAutoLogin."
		   defaults write /Library/Preferences/com.apple.loginwindow DisableFDEAutoLogin -bool YES
	   else
		   echo "FileVault 2 is not enabled."
	   fi
   fi
   
   jamf displayMessage -message "$adequate_free_space_for_install_dialog"
   jamf policy -trigger cache-elcapitan-installer
   jamf policy -trigger run-elcapitan-installer
   shutdown -r now
fi
 
exit 0