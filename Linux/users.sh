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
    echo "No sudo users will be removed. (≧︿≦)"
    exit 0
fi

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

echo "Sucess!! ※\(^o^)/※"
exit 0
