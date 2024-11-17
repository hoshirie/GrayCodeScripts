# PowerShell script to manage user accounts on Windows 10

# Define the list of allowed users
$allowedUsers = @(
    "example", "name"
)

# Define a list of system accounts that should NOT be deleted
$systemAccounts = @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount")

# Define the password to set for unprotected accounts
$defaultPassword = "PasswordPassword@1"

# Get all local user accounts on the system
$allUsers = Get-LocalUser

# Find the users who should be deleted (not in the allowed users list and not in the system accounts list)
$usersToDelete = $allUsers | Where-Object { 
    $_.Name -notin $allowedUsers -and $_.Name -notin $systemAccounts
}

# List users to be deleted
if ($usersToDelete.Count -gt 0) {
    Write-Host "The following users are not in the allowed list and will be deleted:"
    $usersToDelete | ForEach-Object { Write-Host $_.Name }
    
    # Ask for confirmation before deleting
    $confirmation = Read-Host "Are you sure you want to delete these users? (Y/N)"
    if ($confirmation -eq 'Y') {
        foreach ($user in $usersToDelete) {
            try {
                # Delete the user
                Write-Host "Deleting user: $($user.Name)"
                Remove-LocalUser -Name $user.Name -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to delete user $($user.Name): $_"
            }
        }
    } else {
        Write-Host "No users will be deleted."
    }
} else {
    Write-Host "No users need to be deleted. All users are in the allowed list or are system accounts."
}

# Check for unprotected accounts and set a password for them
$unprotectedUsers = $allUsers | Where-Object { 
    $_.Enabled -eq $true -and (Get-LocalUser -Name $_.Name).PasswordRequired -eq $false
}

if ($unprotectedUsers.Count -gt 0) {
    Write-Host "The following unprotected accounts will be given a password:"
    $unprotectedUsers | ForEach-Object { Write-Host $_.Name }

    # Set the default password for these unprotected accounts
    foreach ($user in $unprotectedUsers) {
        try {
            Write-Host "Setting password for user: $($user.Name)"
            Set-LocalUser -Name $user.Name -Password (ConvertTo-SecureString -String $defaultPassword -AsPlainText -Force) -ErrorAction Stop
            Write-Host "Password set for $($user.Name)"
        }
        catch {
            Write-Host "Failed to set password for user $($user.Name): $_"
        }
    }
} else {
    Write-Host "No unprotected accounts found."
}

# Now, display remaining administrators and sudoers
$admins = Get-LocalGroupMember -Group "Administrators"

if ($admins.Count -gt 0) {
    Write-Host "The following users are currently in the Administrators group:"
    $admins | ForEach-Object { Write-Host $_.Name }

    # Ask if the user wants to remove any admins
    $removeAdmin = Read-Host "Do you want to remove any of these admins from the Administrators group? (Y/N)"
    if ($removeAdmin -eq 'Y') {
        # Input multiple admin usernames to remove
        $adminsToRemove = Read-Host "Enter the usernames of the admins you want to remove (comma separated):"
        $adminsToRemoveList = $adminsToRemove -split ',' | ForEach-Object { $_.Trim().ToLower() }

        # Debugging: Show what we are going to remove
        Write-Host "Admins to remove (trimmed and lowercase): $($adminsToRemoveList -join ', ')"

        foreach ($adminToRemove in $adminsToRemoveList) {
            # Normalize group member names (trim spaces and convert to lowercase for comparison)
            $normalizedAdmins = $admins | ForEach-Object { $_.Name.Trim().ToLower() }
            Write-Host "Normalized admins in the group: $($normalizedAdmins -join ', ')"

            # Check if the admin is in the Administrators group (case insensitive comparison)
            if ($normalizedAdmins -contains $adminToRemove) {
                try {
                    # Find the exact user object that matches the normalized name
                    $adminToRemoveObject = $admins | Where-Object { $_.Name.Trim().ToLower() -eq $adminToRemove }
                    
                    # Remove the admin user from the Administrators group (but not delete the account)
                    Write-Host "Removing admin user: $adminToRemove from Administrators group."
                    Remove-LocalGroupMember -Group "Administrators" -Member $adminToRemoveObject -ErrorAction Stop
                    Write-Host "$adminToRemove has been removed from the Administrators group."
                }
                catch {
                    Write-Host "Failed to remove admin $($adminToRemove): $_"
                }
            }
            else {
                Write-Host "$adminToRemove is not a member of the Administrators group."
            }
        }
    } else {
        Write-Host "No admin users will be removed."
    }
} else {
    Write-Host "No users found in the Administrators group."
}

Write-Host "Script completed."
