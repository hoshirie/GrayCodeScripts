#!/bin/bash

# This script will manage users based on a user-defined list, excluding system users.

# Create an array to hold user inputs
declare -a input_users

echo "Enter usernames one by one (press Enter after each). Type 'done' when finished:"

# Read user input
while true; do
    read -r user
    if [[ "$user" == "done" ]]; then
        break
    fi
    input_users+=("$user")
done

# Get the list of existing users, excluding system users (UID < 1000)
existing_users=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)

# Convert input array to a string for easier comparison
input_users_string=$(printf "%s\n" "${input_users[@]}" | sort)

# Find users to delete (those in existing users but not in input list)
users_to_delete=()
for user in $existing_users; do
    if ! echo "$input_users_string" | grep -q "^$user$"; then
        users_to_delete+=("$user")
    fi
done

# Check if there are users to delete
if [ ${#users_to_delete[@]} -eq 0 ]; then
    echo "No users to delete."
else
    # List users to delete
    echo "The following users will be deleted:"
    printf '%s\n' "${users_to_delete[@]}"

    # Ask for user confirmation
    read -p "Do you want to proceed with the deletion? (y/n): " confirm

    if [[ "$confirm" != "y" ]]; then
        echo "Operation canceled."
    else
        # Proceed with deletion
        for user in "${users_to_delete[@]}"; do
            sudo deluser --remove-home "$user"
        done
        echo "Users deleted."
    fi
fi

# Output remaining admin/sudoers
echo "Remaining admin/sudoers:"
getent group sudo | awk -F: '{print $4}' | tr ',' '\n'

# Ask if there are any sudo users to remove
read -p "Are there any sudo users you want to remove from the sudo group? (y/n): " remove_sudo_confirm

if [[ "$remove_sudo_confirm" != "y" ]]; then
    echo "No sudo users will be removed."
else
    # Prompt for sudo users to remove
    echo "Enter sudo usernames to remove from the sudo group one by one (press Enter after each). Type 'done' when finished:"
    declare -a users_to_remove
    while true; do
        read -r sudo_user
        if [[ "$sudo_user" == "done" ]]; then
            break
        fi
        users_to_remove+=("$sudo_user")
    done

    # Remove users from the sudo group
    for user in "${users_to_remove[@]}"; do
        if getent group sudo | grep -q "\b$user\b"; then
            sudo deluser "$user" sudo
            echo "$user has been removed from the sudo group."
        else
            echo "$user is not in the sudo group."
        fi
    done
fi

# Ask if there are any user passwords to change
read -p "Do you want to change the password for any users? (y/n): " change_password_confirm

if [[ "$change_password_confirm" == "y" ]]; then
    echo "Enter usernames one by one (press Enter after each). Type 'done' when finished:"
    declare -a users_to_change_password
    while true; do
        read -r password_user
        if [[ "$password_user" == "done" ]]; then
            break
        fi
        users_to_change_password+=("$password_user")
    done

    for user in "${users_to_change_password[@]}"; do
        if id "$user" &>/dev/null; then
            echo "Changing password for $user to 'PasswordPassword@1'."
            echo "$user:PasswordPassword@1" | sudo chpasswd
            echo "Password for $user has been changed."
        else
            echo "$user does not exist."
        fi
    done
fi

# Ask if there are any new users to create
read -p "Do you want to create any new users? (y/n): " create_users_confirm

if [[ "$create_users_confirm" == "y" ]]; then
    echo "Enter new usernames one by one (press Enter after each). Type 'done' when finished:"
    declare -a new_users
    while true; do
        read -r new_user
        if [[ "$new_user" == "done" ]]; then
            break
        fi
        new_users+=("$new_user")
    done

    # Ask which new users should be granted sudo privileges
    echo "Enter the usernames of the new users you want to grant sudo privileges to (press Enter after each). Type 'done' when finished:"
    declare -a sudo_users
    while true; do
        read -r sudo_user
        if [[ "$sudo_user" == "done" ]]; then
            break
        fi
        sudo_users+=("$sudo_user")
    done

    # Create new users and assign sudo privileges if specified
    for user in "${new_users[@]}"; do
        if id "$user" &>/dev/null; then
            echo "$user already exists."
        else
            echo "Creating user $user."
            sudo adduser --gecos "" "$user"
            echo "User $user has been created."
            if [[ " ${sudo_users[@]} " =~ " $user " ]]; then
                sudo usermod -aG sudo "$user"
                echo "$user has been granted sudo privileges."
            fi
        fi
    done
fi

# Ask if there are any new groups to create
read -p "Do you want to create any new groups? (y/n): " create_groups_confirm

if [[ "$create_groups_confirm" == "y" ]]; then
    echo "Enter new group names one by one (press Enter after each). Type 'done' when finished:"
    declare -a new_groups
    while true; do
        read -r new_group
        if [[ "$new_group" == "done" ]]; then
            break
        fi
        new_groups+=("$new_group")
    done

    # Ask which users should be added to each new group
    for group in "${new_groups[@]}"; do
        echo "Enter usernames to add to group '$group' one by one (press Enter after each). Type 'done' when finished:"
        declare -a group_users
        while true; do
            read -r group_user
            if [[ "$group_user" == "done" ]]; then
                break
            fi
            group_users+=("$group_user")
        done

        # Create the group and add users to it
        sudo groupadd "$group"
        echo "Group '$group' has been created."
        for user in "${group_users[@]}"; do
            if id "$user" &>/dev/null; then
                sudo usermod -aG "$group" "$user"
                echo "$user has been added to group '$group'."
            else
                echo "$user does not exist."
            fi
        done
    done
fi

# PAM Configuration Script
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

# Main execution for PAM configuration
update_pam_config
update_password_age
disable_null_passwords

echo "PAM configuration updated successfully !!"

# Check UFW status
if sudo ufw status | grep -q "inactive"; then
    read -p "UFW firewall is not enabled. Do you want to enable it? (y/n): " enable_ufw
    if [[ "$enable_ufw" == "y" ]]; then
        sudo ufw enable
        echo "UFW has been enabled !!"
    else
        echo "UFW will remain disabled."
    fi
else
    echo "UFW firewall is already enabled."
fi

# Disable SSH root login
sshd_config="/etc/ssh/sshd_config"
if grep -q "^PermitRootLogin yes" "$sshd_config"; then
    sudo sed -i 's/^PermitRootLogin yes/#PermitRootLogin yes/' "$sshd_config"
    echo "Root SSH login has been disabled."
elif grep -q "^PermitRootLogin prohibit-password" "$sshd_config"; then
    echo "Root SSH login is already disabled."
else
    echo "No change made to SSH root login settings."
fi

# Restart SSH service to apply changes
sudo systemctl restart sshd
echo "SSH service restarted."



echo "All done !! make sure to check all current running services and disable or delete any sketchy ones !!!! also the command for that: systemctl list-units --type=service --state=running"
exit 0
