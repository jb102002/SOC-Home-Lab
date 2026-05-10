
#            My AWS Cloud SOC Home Lab with Terraform

## Table of Contents

1. [Lab Overview](#lab-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Terraform Files](#terraform-files)
5. [Deploying the Lab](#deploying-the-lab)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Installing Splunk](#installing-splunk)
8. Configuring the Windows Victim
9. Installing the SUF
10. Fixing Sysmon Permissions
11. Verifying Logs in Splunk
12. Running Attacks from Kali
13. What to Look For in Splunk
14. Cost Management
15. Troubleshooting
16. Key Splunk Searches

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

- variables.tf - Stores all variables for use in all .tf files below
- config.tf - Sets the Cloud Provider and Version
- main.tf - Provider, VPC, Subnet, Internet Gateway, and Route Table
- instances.tf - AMI Lookups and EC2 Instances
- security_groups.tf - Firewall rules for each machine
- outputs.tf - IP's printed after Terraform apply
- windows_userdata.ps1 - PowerShell script that runs on Windows first boot (Configures SUF and Sysmon on boot. Saves a lot of time... trust me xD)

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

For convenience sake, run the command below to enable boot start for splunk
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

> **Important:** Use http:// not https:// and use the public IP not the private IP. The private IP (ip-10-0-1-x) is only reachable from inside AWS.

---

## Configuring the Windows Victim
