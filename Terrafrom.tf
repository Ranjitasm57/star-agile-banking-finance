# Initialize Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}

# Creating a VPC
resource "aws_vpc" "Ranjita_vpc" {
  cidr_block = "172.20.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "R_Gateway" {
  vpc_id = aws_vpc.Ranjita_vpc.id
  tags = {
    Name = "R_Gateway"
  }
}

# Setting up the route table
resource "aws_route_table" "Ranjita_RT" {
  vpc_id = aws_vpc.Ranjita_vpc.id
  route {
    # pointing to the internet
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.R_Gateway.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.R_Gateway.id
  }
  tags = {
    Name = "Ranjita_RT"
  }
}

# Setting up the subnet
resource "aws_subnet" "Ranjita_subnet" {
  vpc_id = aws_vpc.Ranjita_vpc.id
  cidr_block = "172.20.10.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "Ranjita_subnet"
  }
}

# Associating the subnet with the route table
resource "aws_route_table_association" "RT_A" {
  subnet_id = aws_subnet.Ranjita_subnet.id
  route_table_id = aws_route_table.Ranjita_RT.id
}

# Creating a Security Group
resource "aws_security_group" "Ranjita_SG" {
  name = "Ranjita_SG"
  description = "Enable web traffic for the project"
  vpc_id = aws_vpc.Ranjita_vpc.id

  ingress {
    description = "Allow all inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ranjita_SG"
  }
}

# Creating a new network interface
resource "aws_network_interface" "Production_interface" {
  subnet_id = aws_subnet.Ranjita_subnet.id
  private_ips = ["172.20.10.10"]
  security_groups = [aws_security_group.Ranjita_SG.id]
}

# Creating an Ubuntu EC2 instance
resource "aws_instance" "Production_Server" {
  ami = "ami-0ef82eeba2c7a0eeb"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1b"
  key_name = "Project-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.Production_interface.id
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
  EOF
  tags = {
    Name = "Prod-Server"
  }
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "Ranjita_eip" {
  vpc = true
  network_interface = aws_network_interface.Production_interface.id
  associate_with_private_ip = "172.20.10.10"
  depends_on = [aws_instance.Production_Server]
}
