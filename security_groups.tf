# -----------------------------------------------
# SECURITY GROUPS
# Security groups are virtual firewalls that control what
# network traffic is allowed in (ingress) and out (egress)
# of each instance. Each instance gets its own security
# group tailored to what it needs.
#
# ingress = incoming traffic rules
# egress  = outgoing traffic rules
# -----------------------------------------------

# -----------------------------------------------
# SPLUNK SECURITY GROUP
# Splunk needs:
#   Port 22   — SSH so you can manage the server
#   Port 8000 — Splunk web UI so you can search logs in the browser
#   Port 9997 — Receives forwarded logs from the Windows machine
#   Port 8089 — Splunk internal API used by forwarders to check in
# -----------------------------------------------

resource "aws_security_group" "splunk_sg" {
    name        = "Splunk-SG"
    description = "Security Group for Splunk Server"
    vpc_id      = aws_vpc.soc_lab_vpc.id

    # SSH — only allow from your IP so nobody else can log into your server
    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    # Splunk web UI — only allow from your IP so only you can access the dashboard
    ingress {
        description = "Splunk Web UI"
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    # Splunk log receiver — open to the entire VPC so the Windows forwarder
    # inside the VPC can ship logs to Splunk on this port
    ingress {
        description = "Splunk Receiver - forwarders send logs here"
        from_port   = 9997
        to_port     = 9997
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    # Splunk management API — used internally by forwarders to register themselves
    ingress {
        description = "Splunk API"
        from_port   = 8089
        to_port     = 8089
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    # Allow all outbound traffic — Splunk needs to download updates, talk to AWS, etc
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"          # -1 means all protocols
        cidr_blocks = ["0.0.0.0/0"] # Allow to anywhere
    }

    tags = {
        Name = "Splunk-SG"
    }
}

# -----------------------------------------------
# WINDOWS VICTIM SECURITY GROUP
# Windows needs:
#   Port 3389 — RDP so you can remote desktop into it
#   All VPC traffic — so Kali can attack it from inside the lab
#   and so it can send logs to Splunk
# -----------------------------------------------   
    
resource "aws_security_group" "windows_sg" {
    name        = "Windows-Victim-Sg"
    description = "Security group for Windows victim machine"
    vpc_id      = aws_vpc.soc_lab_vpc.id

    # RDP — only allow from your IP so only you can remote desktop in
    ingress {
        description = "RDP"
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    # Allow All traffic from within the VPC
    ingress {
        description = "Allows all traffic from within the Lab VPC"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
    }

    # Allow all outbound traffic so Windows can reach Splunk and the internet
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Windows-Victim-SG"
    }
}

# -----------------------------------------------
# KALI ATTACKER SECURITY GROUP
# Kali only needs:
#   Port 22 — SSH so you can log in and run attacks
#
# We don't open any other inbound ports — Kali is the attacker,
# not a server. It initiates connections, doesn't receive them.
# -----------------------------------------------

resource "aws_security_group" "kali_sg" {
    name        = "Kali-Attacker-SG"
    description = "Security Group for Kali Linux attacker machine"
    vpc_id      = aws_vpc.soc_lab_vpc.id

    # SSH — only allow from your IP
    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    # Allow all outbound so Kali can attack anything inside or outside the VPC
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Kali-Attacker-SG"
    }
}