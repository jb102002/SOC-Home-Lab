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

resource "aws_instance" "splunk" {
    ami                    = data.aws_ami.ubuntu.id 
    instance_type          = var.splunk_instance_type 
    subnet_id              = aws_subnet.soc_lab_subnet.id
    key_name               = var.aws_key_pair 
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

resource "aws_instance" "windows_victim" {
    ami                    = data.aws_ami.windows.id
    instance_type          = var.windows_instance_type
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

    

