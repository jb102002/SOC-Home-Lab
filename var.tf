# -----------------------------------------------
# VARIABLES
# These are like settings you can change without touching
# the rest of the code. Edit the default values here
# to match your environment before running terraform apply.
# -----------------------------------------------

# AWS region where all resources will be created
variable "aws_region" {
    description = "AWS region to deploy lab in"
    default     = "us-east-1"
}

# The name of the SSH key pair you created in the AWS console
# This is NOT the actual key — just the name you gave it in AWS
# Go to EC2 > Key Pairs to find or create one
variable "aws_key_pair" {
    description = "SSH Key Pair name created in AWS (must exist in your region)"
    type        = string
    default     = "YOUR KEY NAME HERE"
}

# Your public IP address in CIDR format.
# This restricts SSH and RDP access to only your machine — important for security
# Find your IP at https://whatismyip.com then add /32 at the end e.g. 1.2.3.4/32
# 0.0.0.0/0 means anyone can connect — fine for a lab but not ideal
variable "my_public_ip" {
    description = "Your public IP in CIDR format (e.g. 1.2.3.4/32)."
    type        = string
    default     = "YOUR PUBLIC IP HERE/32" # Replace with your IP for better security
} 

# The IP range for the entire VPC (your private lab network)
# 10.0.0.0/16 gives you 65,536 private IP addresses — more than enough
variable "vpc_cidr" {
    description = "CIDR block for the lab VPC"
    type        = string
    default     = "10.0.0.0/16"
}

# The IP range for the subnet inside the VPC where your instances live
# Must be a smaller range that fits inside the vpc_cidr above
variable "subnet_cidr" {
    description = "CIDR block for the lab subnet"
    type        = string
    default     = "10.0.1.0/24"
}

# -----------------------------------------------
# INSTANCE TYPES
# These control how powerful each machine is.
# More power = more expensive per hour.
# Chosen for performance within a $100 credit budget
# -----------------------------------------------

# Splunk needs at least 8GB RAM to index and search logs without crawling
# m7i-flex.large gives 2 vCPU and 8GB RAM — solid for a lab
variable "splunk_instance_type" {
    description = "m7i-flex.large recommended - 8GB RAM for indexing"
    type        = string
    default     = "m7i-flex.large"
}

# Windows victim doesn't need much power — it just needs to run and generate logs
# t3.small gives 2 vCPU and 2GB RAM — usable for basic Windows tasks
variable "windows_instance_type" {
    description = "t3.small is fine for a basic Windows victim machine"
    type        = string
    default     = "t3.small"
}

# Kali is your attack machine 
# Tools like nmap and metasploit run fine on t3.small
variable "kali_instance_type" {
    description = "t3.small is plenty for Kali attacker work"
    type        = string
    default     = "t3.small"
}

