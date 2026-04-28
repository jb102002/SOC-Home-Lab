# -----------------------------------------------
# AMI DATA SOURCES
# These automatically look up the latest AMI IDs so you never
# have to hardcode them. AMI IDs change per region and over time
# so always look them up dynamically like this.
# -----------------------------------------------

# Fetch the latest Ubuntu 22.04 LTS from Canonical (official Ubuntu publisher)
# Used for Splunk since it runs best on Linux
data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"] # Canonical's official AWS account ID

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"] # HVM is the modern virtualization standard — required for t3/m7i
    }
}

# Fetch the latest Windows Server 2022 from Amazon's official account.
# Used for the victim machine — Windows generates rich event logs perfect for Splunk
data "aws_ami" "windows" {
    most_recent = true
    owners      = ["801119661308"] # Amazon's official AMI publisher account ID

    filter {
        name   = "name"
        values = ["Windows_Server-2022-English-Full-Base-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# Fetch the latest Kali Linux from the official Kali publisher on AWS Marketplace
# Kali comes preloaded with hundreds of penetration testing tools
data "aws_ami" "kali" {
    most_recent = true
    owners      = ["679593333241"] # Official Kali Linux AWS Marketplace publisher ID

    filter {
        name   = "name"
        values = ["kali-last-snapshot-amd64-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# -----------------------------------------------
# SPLUNK SERVER
# The heart of the SOC lab. All logs from Windows flow here.
# After deploying, SSH in and install Splunk:
#   wget -O splunk.tgz "https://download.splunk.com/products/splunk/releases/9.2.0/linux/splunk-9.2.0-linux-2.6-amd64.tgz"
#   tar xvzf splunk.tgz -C /opt
#   /opt/splunk/bin/splunk start --accept-license
# Then access the UI at http://<public_ip>:8000
# -----------------------------------------------

resource "aws_instance" "splunk" {
    ami                    = data.aws_ami.ubuntu.id # Ubuntu Linux for Splunk
    instance_type          = var.splunk_instance_type # m7i-flex.large 
    subnet_id              = aws_subnet.soc_lab_subnet.id
    key_name               = var.aws_key_pair # Your key pair for SSH
    vpc_security_group_ids = [aws_security_group.splunk_sg.id]

    root_block_device {
        volume_size = 50 # 50GB to store Splunk indexes — shrink if costs are a concern
        volume_type = "gp3" # gp3 is faster and slightly cheaper than gp2
    }

    tags = {
        Name = "J-B-SOC-Lab-Splunk"
        Role = "SIEM"
    }
}

# -----------------------------------------------
# WINDOWS VICTIM MACHINE
# This machine gets attacked by Kali. Sysmon monitors everything
# that happens and the Splunk Universal Forwarder ships those
# logs to Splunk automatically.
#
# The user_data script below runs on first boot and handles
# all the installation automatically — no manual steps needed.
#
# Connect via RDP to the public IP shown in outputs.
# Get the Windows password:
#   AWS Console > EC2 > Instances > Select > Actions > Get Windows Password
#
# STOP THIS IN AWS CONSOLE WHEN NOT USING IT to save money.
# -----------------------------------------------

resource "aws_instance" "windows_victim" {
    ami                    = data.aws_ami.windows.id
    instance_type          = var.windows_instance_type # t3.small
    subnet_id              = aws_subnet.soc_lab_subnet.id
    key_name               = var.aws_key_pair
    vpc_security_group_ids = [aws_security_group.windows_sg.id]

    depends_on = [aws_instance.splunk]

    user_data = templatefile("${path.module}/windows_userdata.ps1", {
        splunk_private_ip = aws_instance.splunk.private_ip
    })

    root_block_device {
        volume_size = 40 # Windows needs more disk space than Linux — 40GB is comfortable
        volume_type = "gp3"
    }

    tags = {
        Name = "SOC-Lab-Windows-Victim"
        Role = "Victim"
    }
}

# -----------------------------------------------
# KALI ATTACKER MACHINE
# Your offensive machine. SSH in and run attacks against
# the Windows victim. Watch the Sysmon and Security logs
# light up in Splunk as your attacks are detected.
#
# Useful tools already on Kali:
#   nmap       — port scanning and service discovery
#   metasploit — exploitation framework
#   hydra      — brute force login attacks
#   netcat     — raw network connections
#
# SSH in with: ssh -i your-key.pem kali@<public_ip>
# STOP THIS IN AWS CONSOLE WHEN NOT USING IT to save money.
# -----------------------------------------------

resource "aws_instance" "kali_attacker" {
    ami                    = data.aws_ami.kali.id
    instance_type          = var.kali_instance_type
    subnet_id              = aws_subnet.soc_lab_subnet.id
    key_name               = var.aws_key_pair
    vpc_security_group_ids = [aws_security_group.kali_sg.id]

    root_block_device {
        volume_size = 20 # 20GB is enough for Kali and its tools
        volume_type = "gp3"
    }

    tags = {
        Name = "SOC-Lab-Kali-Attacker"
        Role = "Attacker"
    }
}

    

