provider "aws" {
  region = var.region
}

# -------------------------------
# VPC and Networking
# -------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az1
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
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------
# Key Pair
# -------------------------------
resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible-key"
  public_key = file(var.public_key_path)
}

# -------------------------------
# AMI (Ubuntu)
# -------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# -------------------------------
# Security Groups
# -------------------------------
resource "aws_security_group" "controller_sg" {
  name        = "controller-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Controller-sg"
  }
}

resource "aws_security_group" "target_node_sg" {
  name   = "target-node-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Target-node-sg"
  }
}

# -------------------------------
# Target EC2 Instance
# -------------------------------
resource "aws_instance" "target_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids      = [aws_security_group.target_node_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "Target-node"
  }
}

# -------------------------------
# Controller EC2 Instance (Ansible installed)
# -------------------------------
resource "aws_instance" "ansible_controller" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids      = [aws_security_group.controller_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  # Copy ansible key before running remote-exec
provisioner "file" {
  source      = var.private_key_path
  destination = "/home/ubuntu/ansible-key"
}

provisioner "file" {
  source      = "${path.module}/../ansible/playbook.yml"
  destination = "/home/ubuntu/playbook.yml"
}

provisioner "remote-exec" {
  inline = [
    "chmod 400 /home/ubuntu/ansible-key",
    "sudo apt update -y",
    "sudo apt install -y software-properties-common",
    "sudo add-apt-repository --yes --update ppa:ansible/ansible",
    "sudo apt update -y",
    "sudo apt install -y ansible",
    "ansible-playbook /home/ubuntu/playbook.yml -e target_private_ip=${aws_instance.target_node.private_ip}"
  ]
}

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  tags = {
    Name = "Ansible-controller"
  }
}
