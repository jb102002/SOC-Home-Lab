variable "aws_region" {
    description = "AWS region to deploy lab in"
    default     = "us-east-1"
}

variable "aws_key_pair" {
    description = "SSH Key Pair name created in AWS (must exist in your region)"
    type        = string
    default     = "YOUR KEY NAME HERE" # Replace with you key pair name
}

variable "my_public_ip" {
    description = "Your public IP in CIDR format (e.g. 1.2.3.4/32)."
    type        = string
    default     = "YOUR PUBLIC IP HERE/32" # Replace with your IP for better security
} 

variable "vpc_cidr" {
    description = "CIDR block for the lab VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
    description = "CIDR block for the lab subnet"
    type        = string
    default     = "10.0.1.0/24"
}

variable "splunk_instance_type" {
    description = "m7i-flex.large recommended - 8GB RAM for indexing"
    type        = string
    default     = "m7i-flex.large"
}

variable "windows_instance_type" {
    description = "t3.small is fine for a basic Windows victim machine"
    type        = string
    default     = "t3.small"
}

variable "kali_instance_type" {
    description = "t3.small is plenty for Kali attacker work"
    type        = string
    default     = "t3.small"
}

