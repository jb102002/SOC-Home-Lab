resource "aws_security_group" "splunk_sg" {
    name        = "Splunk-SG"
    description = "Security Group for Splunk Server"
    vpc_id      = aws_vpc.soc_lab_vpc.id

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    ingress {
        description = "Splunk Web UI"
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    ingress {
        description = "Splunk Receiver - forwarders send logs here"
        from_port   = 9997
        to_port     = 9997
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

    ingress {
        description = "Splunk API"
        from_port   = 8089
        to_port     = 8089
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
    }

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

resource "aws_security_group" "windows_sg" {
    name        = "Windows-Victim-Sg"
    description = "Security group for Windows victim machine"
    vpc_id      = aws_vpc.soc_lab_vpc.id

    ingress {
        description = "RDP"
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

    ingress {
        description = "Allows all traffic from within the Lab VPC"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
    }

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

resource "aws_security_group" "kali_sg" {
    name        = "Kali-Attacker-SG"
    description = "Security Group for Kali Linux attacker machine"
    vpc_id      = aws_vpc.soc_lab_vpc.id

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_public_ip]
    }

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