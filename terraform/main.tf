provider "aws" {
  region = var.region
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id 
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.az1
    map_public_ip_on_launch = true
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "public_assoc" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible-key"
  public_key = file(var.public_key_path) 
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}

resource "aws_security_group" "controller_sg" {
    vpc_id = aws_vpc.main_vpc.id
    name = "controller-sg"
    description = "Allow SSH"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Controller-sg"
    }
}

resource "aws_security_group" "target_node_sg" {
    vpc_id = aws_vpc.main_vpc.id
    name = "target-node-sg"


    ingress {
        description = "for ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "for jenkins"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "for flask-app"
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Target-node-sg"
    }
}

resource "aws_instance" "ansible_controller" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = aws_key_pair.ansible_key.key_name
    vpc_security_group_ids = [aws_security_group.controller_sg.id]
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = true

    tags = {
        Name = "Ansible-controller"
    }
}

resource "aws_instance" "target_node" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = aws_key_pair.ansible_key.key_name
    vpc_security_group_ids = [aws_security_group.target_node_sg.id]
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = true

    tags = {
        Name = "Target-node"
    }
}