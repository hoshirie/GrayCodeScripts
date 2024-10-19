#!/bin/bash

# This script configures PAM to enforce password policies.

# Function to update PAM configuration
update_pam_config() {
    # Check if the configuration file exists
    if [[ ! -f /etc/pam.d/common-password ]]; then
        echo "PAM configuration file not found."
        exit 1
    fi

    # Create a backup of the original common-password file
    cp /etc/pam.d/common-password /etc/pam.d/common-password.bak
    echo "Backup of common-password created at /etc/pam.d/common-password.bak"

    # Update the common-password file to enforce password policies
    sed -i.bak '/^password/ s/\(.*pam_unix.so\)/\1 minlen=12 remember=5/' /etc/pam.d/common-password

    echo "Updated common-password to enforce minimum length of 12 characters."
}

# Function to update password aging policies
update_password_age() {
    # Update the /etc/login.defs file
    if [[ ! -f /etc/login.defs ]]; then
        echo "login.defs file not found."
        exit 1
    fi

    # Set password aging parameters
    sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN 12/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 5/' /etc/login.defs
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 30/' /etc/login.defs

    echo "Updated login.defs for password aging policies."
}

# Function to disable null passwords
disable_null_passwords() {
    # Update the common-password file to disallow null passwords
    sed -i '/^password/ s/pam_unix.so/& nullok//' /etc/pam.d/common-password

    echo "Updated PAM to disallow null passwords."
}

# Main execution
update_pam_config
update_password_age
disable_null_passwords

echo "PAM configuration updated successfully."
exit 0
