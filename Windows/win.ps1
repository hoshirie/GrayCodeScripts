# User Management Script in PowerShell

# Array to hold user inputs
$inputUsers = @()

Write-Host "Enter usernames one by one (press Enter after each). Type 'done' when finished:"
while ($true) {
    $user = Read-Host
    if ($user -eq 'done') { break }
    $inputUsers += $user
}

# Get existing users (ignoring system accounts)
$existingUsers = Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true -and $_.SID -match 'S-1-5-21' } | Select-Object -ExpandProperty Name

# Users to delete (those in existingUsers but not in input list)
$usersToDelete = $existingUsers | Where-Object { $_ -notin $inputUsers }

if ($usersToDelete.Count -eq 0) {
    Write-Host "No users to delete."
} else {
    Write-Host "The following users will be deleted:"
    $usersToDelete | ForEach-Object { Write-Host $_ }
    
    $confirm = Read-Host "Do you want to proceed with the deletion? (y/n)"
    if ($confirm -ne 'y') {
        Write-Host "Operation canceled."
    } else {
        foreach ($user in $usersToDelete) {
            Remove-LocalUser -Name $user -Force
            Write-Host "$user deleted."
        }
    }
}

# Output remaining admin/sudoers (Administrators group members)
Write-Host "Remaining admin/sudoers:"
Get-LocalGroupMember -Group 'Administrators' | ForEach-Object { Write-Host $_.Name }

# Sudo users removal
$removeSudoConfirm = Read-Host "Are there any sudo users you want to remove from the sudo group? (y/n)"
if ($removeSudoConfirm -eq 'y') {
    Write-Host "Enter sudo usernames to remove from the sudo group one by one. Type 'done' when finished:"
    $sudoUsersToRemove = @()
    while ($true) {
        $sudoUser = Read-Host
        if ($sudoUser -eq 'done') { break }
        $sudoUsersToRemove += $sudoUser
    }

    foreach ($user in $sudoUsersToRemove) {
        Remove-LocalGroupMember -Group 'Administrators' -Member $user -ErrorAction SilentlyContinue
        Write-Host "$user has been removed from the sudo group."
    }
}

# Password changes
$changePasswordConfirm = Read-Host "Do you want to change the password for any users? (y/n)"
if ($changePasswordConfirm -eq 'y') {
    Write-Host "Enter usernames one by one to change their password. Type 'done' when finished:"
    $passwordUsers = @()
    while ($true) {
        $passwordUser = Read-Host
        if ($passwordUser -eq 'done') { break }
        $passwordUsers += $passwordUser
    }

    foreach ($user in $passwordUsers) {
        if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
            $password = ConvertTo-SecureString "PasswordPassword@1" -AsPlainText -Force
            Set-LocalUser -Name $user -Password $password
            Write-Host "Password for $user has been changed."
        } else {
            Write-Host "$user does not exist."
        }
    }
}

# New user creation
$createUsersConfirm = Read-Host "Do you want to create any new users? (y/n)"
if ($createUsersConfirm -eq 'y') {
    Write-Host "Enter new usernames one by one. Type 'done' when finished:"
    $newUsers = @()
    while ($true) {
        $newUser = Read-Host
        if ($newUser -eq 'done') { break }
        $newUsers += $newUser
    }

    # Grant sudo privileges if specified
    Write-Host "Enter the usernames of the new users to grant sudo privileges to. Type 'done' when finished:"
    $sudoUsers = @()
    while ($true) {
        $sudoUser = Read-Host
        if ($sudoUser -eq 'done') { break }
        $sudoUsers += $sudoUser
    }

    foreach ($user in $newUsers) {
        if (!(Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $user -NoPassword -AccountNeverExpires
            Write-Host "User $user has been created."

            if ($sudoUsers -contains $user) {
                Add-LocalGroupMember -Group 'Administrators' -Member $user
                Write-Host "$user has been granted sudo privileges."
            }
        } else {
            Write-Host "$user already exists."
        }
    }
}

# New group creation
$createGroupsConfirm = Read-Host "Do you want to create any new groups? (y/n)"
if ($createGroupsConfirm -eq 'y') {
    Write-Host "Enter new group names one by one. Type 'done' when finished:"
    $newGroups = @()
    while ($true) {
        $newGroup = Read-Host
        if ($newGroup -eq 'done') { break }
        $newGroups += $newGroup
    }

    foreach ($group in $newGroups) {
        New-LocalGroup -Name $group -ErrorAction SilentlyContinue
        Write-Host "Group '$group' has been created."
    }
}

# Password policy enforcement (requires editing local policies)
Write-Host "Enforcing password policy settings (e.g., minimum length, complexity)."
# This requires modifying local policies and group policies, so manual steps may be involved on a Windows system.

# UFW Firewall Status Check (available on Linux PowerShell)
if (Get-Command "ufw" -ErrorAction SilentlyContinue) {
    $ufwStatus = ufw status
    if ($ufwStatus -match "inactive") {
        $enableUfw = Read-Host "UFW firewall is not enabled. Do you want to enable it? (y/n)"
        if ($enableUfw -eq 'y') {
            sudo ufw enable
            Write-Host "UFW has been enabled."
        } else {
            Write-Host "UFW will remain disabled."
        }
    } else {
        Write-Host "UFW firewall is already enabled."
    }
}

# SSH root login disabling (Linux-specific)
if (Test-Path "/etc/ssh/sshd_config") {
    $sshdConfig = Get-Content "/etc/ssh/sshd_config"
    if ($sshdConfig -match "^PermitRootLogin yes") {
        (Get-Content "/etc/ssh/sshd_config") -replace "PermitRootLogin yes", "#PermitRootLogin yes" | Set-Content "/etc/ssh/sshd_config"
        Write-Host "Root SSH login has been disabled."
    } elseif ($sshdConfig -match "^PermitRootLogin prohibit-password") {
        Write-Host "Root SSH login is already disabled."
    } else {
        Write-Host "No change made to SSH root login settings."
    }
    sudo systemctl restart sshd
    Write-Host "SSH service restarted."
}

# List active services
Write-Host "Check all current running services and disable or delete any sketchy ones!"
Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object DisplayName, Status | Format-Table -AutoSize

Write-Host "All done!"
exit
