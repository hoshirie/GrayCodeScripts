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
    exit 0
fi

# List users to delete
echo "The following users will be deleted:"
printf '%s\n' "${users_to_delete[@]}"

# Ask for user confirmation
read -p "Do you want to proceed with the deletion? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
    echo "Operation canceled."
    exit 0
fi

# Proceed with deletion
for user in "${users_to_delete[@]}"; do
    sudo deluser --remove-home "$user"
done

echo "Users deleted."

# Output remaining admin/sudoers
echo "Remaining admin/sudoers:"
getent group sudo | awk -F: '{print $4}' | tr ',' '\n'

exit 0
