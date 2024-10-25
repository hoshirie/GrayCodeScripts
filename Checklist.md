# GO THROUGH FORENSICS BEFORE RUNNING ANY SCRIPTS

## Ubuntu/Mint General Tasks

### System Check & Updates

- Check critical services, users, and important info
- Run scripts, check for forensic questions
- Remove malware/unwanted applications
- Update all necessary applications to the latest version
- Update repositories
- Set default browser and disable pop-ups
- Review all users (super users, unwanted users, add any new ones if needed)
- Enforce password complexity with PAM
- Verify users’ password strength (no numbers, symbols, or short passwords)
- Enable firewall

### Important Commands

- Locate a specific file: locate *[file type]
- Find hidden files: `ls -la` or `ls -lsa`
- List all super users: `grep -Po '^sudo.+:\K.*$' /etc/group` `getent group sudo` `less /etc/group | grep sudo`
- Remove super user privileges (without deleting user): `sudo deluser [username] sudo`
- Create a group: `sudo addgroup [group name]`
- Add user to group: `sudo adduser [username] [group name]`
- Check all users: `cat /etc/passwd`
- Install applications: `sudo apt-get install [application name]`
- Check application version: `[application name] --version`
- Update an application: `sudo apt install [application name]`
- Enforce password complexity: Edit `/etc/pam.d/common-password`
  - `sudo nano /etc/pam.d/common-password`
    - `And then password requisite pam_pwquality.so retry=3 minlen=8 ucredit=-1 dcredit=-1`
- Check UFW firewall: `sudo ufw status`
  - If inactive, enable: `sudo ufw enable`
- Disable root login in SSH: `sudo nano /etc/ssh/sshd_config`, set `PermitRootLogin no` and save
- List all running services: `systemctl --type=service --state=running`
- Start a service: `sudo systemctl start [service]`
- Stop a service: `sudo systemctl stop [service]`
- Restart a service: `sudo systemctl restart [service]`
- Find UID of deleted user: `find / -uid [UID] 2>/dev/null` 


## Windows General Tasks

### System Check & Updates

- Check critical services, users, and important info
- Run forensic checks
- Remove malware/unwanted applications
- Review all users (administrators, unwanted users, add any new ones if needed)
- Update necessary applications to latest version
- Set and update default browser settings
- Perform a virus scan with Windows Defender
- Enable WiFi DHCP (if disabled)
- Leave big Windows Updates for the end

### Important Commands

- Properties of each user: `lusrmgr.msc` (in Run dialog)
- Security policies: `secpol.msc` (in Run dialog)
- Check for password protection: `Control Panel` > `User Accounts` > `Manage another account`
- Set Audit Credential Validation to [Failure]:
  - Open `secpol.msc`, navigate to `Account Logon` > `Audit Credential Validation`
    - Configure each box to `Failure` > Click `OK`
- Disable anonymous SAM enumeration:
  - Open `secpol.msc`, navigate to `Local Policies` > `Security Options` > `Network access: Do not allow anonymous enumeration of SAM accounts` > Set to `Enable`
- Disable Remote Assistance connections:
  - `Control Panel` > `System` > `Remote settings` > Uncheck `Allow Remote Assistance` > `OK`
- Ensure user’s password expires:
  - Run `lusrmgr.msc`, select `Users`, right-click on user properties > Uncheck `Password never expires`, check `User must change password at next logon` > `Apply`
- Find port for an .exe if PID is known: 
  - `netstat -ano | findstr [PID]` in CMD
- Update an application internally:
  = Open [application] > `Help` > `About [program]` > Update to latest version

## Windows General Server Tasks

### System Check & Updates

- Check critical services, users, and important info
- Run forensic checks
- Remove malware/unwanted applications
- Review all users (administrators, unwanted users, add any new ones if needed)
- Limit local use of blank passwords to console only
- Check running services in service management
- Update the browser to the latest version
- Leave major Windows Updates for the end 

### Important Commands

- Limit use of blank passwords locally:
- Open `secpol.msc`, navigate to `Accounts` > `Limit local account use of blank passwords to console logon only` > `Enable` and `apply`
  - Ensure Windows Event Log Service is running:
    - Run `services.msc`, find `Windows Event Log Service` > Set to `Automatic` > `Apply`
  - Disable FTP service (unless required):
    - Run `services.msc`, find `Microsoft FTP Service` > Set to `Disabled` > `Stop` > `Apply`
  - Enable automatic Windows Updates:
    - Open `gpedit.msc`, navigate to `Administrative Templates` > `Windows Components` > `Windows Update` > Set `Configure Automatic Updates` to `Enabled`
  - Enforce password history:
    - Run dialog > `Security Settings` > `Password Policy` > `Set Keep password history for 5 passwords`
  - Set Audit Detailed File Share to [Failure]:
    - Open `Security Settings` > `Advanced Audit Policy Configuration` > `System Audit Policies` > `Object Access` > `Set Audit Detailed File Share` to `Failure`
- Restrict network access to "Everyone":
- Open `secpol.msc` > `User Rights Assignment` > `Access this computer from the network` > Select `Everyone` > Click `Remove`
- Enable Microsoft network server digital signing:
  - Open `secpol.msc` > `Local Policies` > `Security Options` > Set `Microsoft network server: Digitally sign communications (always)` to `Enabled`
- Disable "Everyone" permissions for anonymous users:
  - Open `secpol.msc` > `Security Settings` > `Local Policies` > `Security Options` > Double click on `Network Access: Let Everyone permissions apply to anonymous users` > select `Disabled` > hit `Ok` and `Yes`
- Install Defender Antivirus:
  - Open `Server Manager` > `Add Roles and Features` > Microsoft Defender Antivirus > Select checkbox > Apply and Restart if required
- Disable sharing on hidden shares like donttouch$:
  - Run `fsmgmt.msc`, find `donttouch$` > Right-click `Stop Sharing` > `Confirm`
- Ensure Windows Defender does not exclude .exe:
  - Open `gpedit.msc` > `Microsoft Defender Antivirus` > Set `Extension Exclusions` to `Not Configured`
    - Then open `Virus and Threat Protection settings` > `Manage exclusions` > `Remove .exe`
