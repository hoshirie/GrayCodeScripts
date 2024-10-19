import subprocess
import os

def run_command(command):
    """Run a command and return the output."""
    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        return output.decode()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e.output.decode()}")
        return None

def set_password_policy():
    print("Setting password policy...")
    commands = [
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /PasswordHistorySize=10',
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /MaximumPasswordAge=30',
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /MinimumPasswordAge=10',
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /MinimumPasswordLength=14',
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /PasswordComplexity=1'
    ]
    for command in commands:
        run_command(command)
    run_command('secedit /import /cfg "C:\\secedit.cfg" /areas securitypolicy')
    print("Password policy set.")

def set_account_lockout_policy():
    print("Setting account lockout policy...")
    commands = [
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /LockoutBadCount=5',
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /LockoutDuration=30',
        'secedit /set /cfg "C:\\secedit.cfg" /areas securitypolicy /ResetLockoutCount=30'
    ]
    for command in commands:
        run_command(command)
    run_command('secedit /import /cfg "C:\\secedit.cfg" /areas securitypolicy')
    print("Account lockout policy set.")

def set_audit_policy():
    print("Setting audit policy...")
    audit_commands = [
        'auditpol /set /subcategory:"Logon/Logoff" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Account Management" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Policy Change" /success:enable /failure:enable',
        'auditpol /set /subcategory:"Privilege Use" /success:enable /failure:enable',
        'auditpol /set /subcategory:"System" /success:enable /failure:enable'
    ]
    for command in audit_commands:
        run_command(command)
    print("Audit policy set.")

def set_security_options():
    print("Setting security options...")
    run_command('secedit /export /cfg "C:\\secedit.cfg"')
    with open("C:\\secedit.cfg", "r") as file:
        lines = file.readlines()
    
    with open("C:\\secedit.cfg", "w") as file:
        for line in lines:
            if 'LimitBlankPasswordUse' in line:
                line = 'LimitBlankPasswordUse=1\n'
            file.write(line)
    
    run_command('secedit /import /cfg "C:\\secedit.cfg" /areas securitypolicy')
    print("Security options set.")

def cleanup():
    print("Cleaning up...")
    if os.path.exists("C:\\secedit.cfg"):
        os.remove("C:\\secedit.cfg")
    print("Cleanup done.")

if __name__ == "__main__":
    set_password_policy()
    set_account_lockout_policy()
    set_audit_policy()
    set_security_options()
    cleanup()
    print("All policies have been configured.")
