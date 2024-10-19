# Ensure you run this as an Administrator

# Set Password Policy
try {
    $passwordPolicy = @{
        PasswordHistorySize = 10
        MaximumPasswordAge = 30
        MinimumPasswordAge = 10
        MinimumPasswordLength = 14
        PasswordComplexity = 1
    }
    foreach ($policy in $passwordPolicy.GetEnumerator()) {
        secedit /set /cfg "C:\secedit.cfg" /areas securitypolicy /$($policy.Key)=$($policy.Value)
    }
    secedit /import /cfg "C:\secedit.cfg" /areas securitypolicy
    Write-Host "Password policy set successfully."
} catch {
    Write-Host "Error setting password policy: $_"
}

# Set Account Lockout Policy
try {
    $accountLockoutPolicy = @{
        LockoutBadCount = 5
        LockoutDuration = 30
        ResetLockoutCount = 30
    }
    foreach ($policy in $accountLockoutPolicy.GetEnumerator()) {
        secedit /set /cfg "C:\secedit.cfg" /areas securitypolicy /$($policy.Key)=$($policy.Value)
    }
    secedit /import /cfg "C:\secedit.cfg" /areas securitypolicy
    Write-Host "Account lockout policy set successfully."
} catch {
    Write-Host "Error setting account lockout policy: $_"
}

# Set Audit Policy
try {
    auditpol /set /subcategory:"Logon/Logoff" /success:enable /failure:enable
    auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable
    auditpol /set /subcategory:"Account Management" /success:enable /failure:enable
    auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable
    auditpol /set /subcategory:"Policy Change" /success:enable /failure:enable
    auditpol /set /subcategory:"Privilege Use" /success:enable /failure:enable
    auditpol /set /subcategory:"System" /success:enable /failure:enable
    Write-Host "Audit policy set successfully."
} catch {
    Write-Host "Error setting audit policy: $_"
}

# Set Security Options
try {
    secedit /export /cfg "C:\secedit.cfg"
    (Get-Content "C:\secedit.cfg") -replace 'LimitBlankPasswordUse=.*', 'LimitBlankPasswordUse=1' |
        Set-Content "C:\secedit.cfg"
    secedit /import /cfg "C:\secedit.cfg" /areas securitypolicy
    Write-Host "Security options set successfully."
} catch {
    Write-Host "Error setting security options: $_"
}

# Clean up
Remove-Item "C:\secedit.cfg" -ErrorAction SilentlyContinue
