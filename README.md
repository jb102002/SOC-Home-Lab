
#            My AWS Cloud SOC Home Lab with Terraform

## Table of Contents

1. Lab Overview
2. Architecture
3. Prerequisites
4. Terraform Files
5. Deploying the Lab
6. Post-Deployment Configuration
7. Intalling Splunk
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

1. #### Configure New User in AWS
  - Go to AWS Console -> IAM -> IAM Users -> Create User
  - Create a username
  - Attach policies directly (AmazonVPCFullAccess + AmazonEC2FullAccess)

2. #### Create an Access Key
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

1. #### Clone the Github .tf Files
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

4. #### Deploy the Lab
```bash
terraform apply -var="aws-key=REPLACE_WITH_NAME_OF_KEY_PAIR"
```
> **Note:** Use the Key Pair you created in the EC2 section not the Access Key















            
            
Project Summary 

terraform init
terraform plan
terraform apply 


*Have to put terraform.exec in PATH

SSH into Splunk Server

ssh -i "C:\Users\user\AWS SOC Lab Terra\example.pem" ubuntu@1.2.3.4

NOTE: Before using SSH to connect to Splunk Instance you may have to change the file permissions of your .pem file where you stored your SHH key pair

 Store the path in a variable to make it easier
$keyPath = "C:\Users\user\AWS SOC Lab Terra\example.pem"

 Remove all inherited permissions
icacls $keyPath /inheritance:r

 Remove the BUILTIN\Users group access
icacls $keyPath /remove "BUILTIN\Users"

 Remove EVERYONE access just in case
icacls $keyPath /remove "Everyone"

 Give only your user account full access
icacls $keyPath /grant:r "user:F"


#Configuring splunk server
1. *sudo tar xvzf * must run sudo to extract to /opt

2. export SPLUNK_HOME=/opt/splunk
$SPLUNK_HOME/bin/splunk start --accept-license

3. sudo chown -R ubuntu:ubuntu /opt/splunk *Ubuntu user does not own splunk folder*

sudo /opt/splunk/bin/splunk enable boot-start -user ubuntu *enable splunk to start on boot

#Configuring universal forwarder on victim machine
Script ran but had problem, I think the splunk universal forwarder path was not correct and needed to log in to website to get correct command


