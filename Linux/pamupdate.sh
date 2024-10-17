#!/bin/bash

# Define parameters
MIN_LENGTH=8

# Function to update common-password file
update_pam_config() {
    local file="/etc/pam.d/common-password"
    
    # Backup the original file
    cp "$file" "${file}.bak"

    # Update the line for password length and prevent null passwords
    if grep -q "pam_unix.so" "$file"; then
        sed -i "s/pam_unix.so.*/& min=$MIN_LENGTH nullok_secure/" "$file"
        echo "Updated $file to set minimum password length to $MIN_LENGTH and prevent null passwords."
    else
        echo "pam_unix.so not found in $file."
        exit 1
    fi
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Execute the update
update_pam_config
