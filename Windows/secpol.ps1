# Ensure you run the script as an administrator

# Define password policies
Set-LocalUser -Name "Administrator" -PasswordNeverExpires $false

# Set password policy settings
secedit /export /cfg "C:\secedit.cfg"
(Get-Content "C:\secedit.cfg") -replace 'PasswordHistorySize=.*', 'PasswordHistorySize=10' |
    ForEach-Object { $_ -replace 'MaximumPasswordAge=.*', 'MaximumPasswordAge=30' } |
    ForEach-Object { $_ -replace 'MinimumPasswordAge=.*', 'MinimumPasswordAge=10' } |
    ForEach-Object { $_ -replace 'MinimumPasswordLength=.*', 'MinimumPasswordLength=14' } |
    ForEach-Object { $_ -replace 'PasswordComplexity=.*', 'PasswordComplexity=1' } |
    Set-Content "C:\secedit.cfg"
secedit /import /cfg "C:\secedit.cfg" /areas securitypolicy

# Set account lockout policy settings
secedit /export /cfg "C:\secedit.cfg"
(Get-Content "C:\secedit.cfg") -replace 'LockoutBadCount=.*', 'LockoutBadCount=5' |
    ForEach-Object { $_ -replace 'LockoutDuration=.*', 'LockoutDuration=30' } |
    ForEach-Object { $_ -replace 'ResetLockoutCount=.*', 'ResetLockoutCount=30' } |
    Set-Content "C:\secedit.cfg"
secedit /import /cfg "C:\secedit.cfg" /areas securitypolicy

# Set audit policy
auditpol /set /subcategory:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable
auditpol /set /subcategory:"Policy Change" /success:enable /failure:enable
auditpol /set /subcategory:"Privilege Use" /success:enable /failure:enable
auditpol /set /subcategory:"System" /success:enable /failure:enable

# Set security options
secedit /export /cfg "C:\secedit.cfg"
(Get-Content "C:\secedit.cfg") -replace 'LimitBlankPasswordUse=.*', 'LimitBlankPasswordUse=1' |
    Set-Content "C:\secedit.cfg"
secedit /import /cfg "C:\secedit.cfg" /areas securitypolicy

# Clean up
Remove-Item "C:\secedit.cfg"

Write-Host "Password policies, account lockout policies, audit policies, and security options have been configured."
