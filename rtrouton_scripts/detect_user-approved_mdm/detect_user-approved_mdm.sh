#!/bin/bash

# Script which reports if user-approved mobile device management
# is enabled on a particular Mac.

UAMDMCheck(){

# This function checks if a Mac has user-approved MDM enabled.
# If the UAMDMStatus variable returns "User Approved", then the
# following status is returned:
#
# Yes
#
# If anything else is returned, the following status is
# returned:
#
# No

UAMDMStatus=$(profiles status -type enrollment | grep -o "User Approved")

if [[ "$UAMDMStatus" = "User Approved" ]]; then
   result="Yes"
else
   result="No"
fi
}

# Check to see if the OS version of the Mac includes a version of the profiles tool which
# can report on user-approved MDM. If the OS check passes, run the UAMDMCheck function.

# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -eq 13 && ${osvers_dot_version} -ge 4 ) || ( ${osvers_major} -eq 10 && ${osvers_minor} -gt 13 ) || ( ${osvers_major} -eq 11 && ${osvers_minor} -ge 0 ) ]]; then
    UAMDMCheck
else

# If the OS check did not pass, the script sets the following string for the "result" value:
#
# "Unable To User-Approved MDM On", followed by the OS version. (no quotes)

    result="Unable To Detect User-Approved MDM On $(/usr/bin/sw_vers -productVersion)"
fi

echo "$result"