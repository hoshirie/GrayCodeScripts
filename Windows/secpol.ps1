# PowerShell script to enforce secure password policies, account lockout policies, and auditing

# Define password policy settings
$minPasswordLength = 12
$maxPasswordAgeDays = 60
$minPasswordAgeDays = 1
$lockoutThreshold = 5
$lockoutDurationMinutes = 15
$lockoutResetMinutes = 15

# Function to set password policy
function Set-PasswordPolicy {
    Write-Host "Setting password policies..."

    # Set minimum password length
    net accounts /minpwlen:$minPasswordLength
    # Set maximum password age
    net accounts /maxpwage:$maxPasswordAgeDays
    # Set minimum password age
    net accounts /minpwage:$minPasswordAgeDays
    
    # Set password complexity
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-ItemProperty -Path $regPath -Name "PasswordComplexity" -Value 1
    Set-ItemProperty -Path $regPath -Name "MinimumPasswordLength" -Value $minPasswordLength
}

# Function to set account lockout policy
function Set-LockoutPolicy {
    Write-Host "Setting account lockout policies..."
    
    # Use secedit to configure lockout settings
    $seceditConfig = @"
[System]
LockoutBadCount = $lockoutThreshold
LockoutDuration = $lockoutDurationMinutes
ResetLockoutCount = $lockoutResetMinutes
"@
    
    # Export current security policy
    $seceditPath = "C:\Windows\Temp\secpol.cfg"
    $seceditConfig | Set-Content -Path $seceditPath
    secedit /import /cfg $seceditPath /areas SECURITYPOLICY
    Remove-Item $seceditPath
}

# Function to enable auditing
function Enable-Auditing {
    Write-Host "Enabling auditing for account logon events..."
    
    # Enable auditing for logon events
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable
}

# Run functions
Set-PasswordPolicy
Set-LockoutPolicy
Enable-Auditing

Write-Host "Security policies have been updated."
