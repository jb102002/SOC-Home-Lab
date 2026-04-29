
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

## Architecture

<img width="636" height="630" alt="image" src="https://github.com/user-attachments/assets/bf34485b-e463-49d5-8599-f32a2ee7af3c" />

## Prerequisites
















            
            
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


