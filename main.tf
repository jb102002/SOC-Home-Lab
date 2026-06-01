resource "aws_vpc" "soc_lab_vpc" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "J-B-SOC-Lab-VPC"
    }
}

resource "aws_subnet" "soc_lab_subnet" {
    vpc_id                  = aws_vpc.soc_lab_vpc.id
    cidr_block              = var.subnet_cidr
    map_public_ip_on_launch = true

    tags = {
        Name = "J-B-SOC-Lab-Subnet"
    }
}

resource "aws_internet_gateway" "soc_lab_igw" {
    vpc_id = aws_vpc.soc_lab_vpc.id

    tags = {
        Name = "J-B-SOC-Lab-IGW"
    }
}

resource "aws_route_table" "soc_lab_rt" {
    vpc_id = aws_vpc.soc_lab_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.soc_lab_igw.id
    }

    tags = {
        Name = "J-B-SOC-Lab-RT"
    }
}

resource "aws_route_table_association" "soc_lab_rta" {
    subnet_id      = aws_subnet.soc_lab_subnet.id
    route_table_id = aws_route_table.soc_lab_rt.id
}

