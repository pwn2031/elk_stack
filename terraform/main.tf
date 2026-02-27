terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# Networking (VPC + subnet)
############################

resource "aws_vpc" "elk_vpc" {
  cidr_block           = var.vpc_cidr          # e.g. "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "elk-vpc"
  }
}

resource "aws_internet_gateway" "elk_igw" {
  vpc_id = aws_vpc.elk_vpc.id

  tags = {
    Name = "elk-igw"
  }
}

resource "aws_subnet" "elk_public_subnet" {
  vpc_id                  = aws_vpc.elk_vpc.id
  cidr_block              = var.public_subnet_cidr    # e.g. "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "elk-public-subnet"
  }
}

resource "aws_route_table" "elk_public_rt" {
  vpc_id = aws_vpc.elk_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.elk_igw.id
  }

  tags = {
    Name = "elk-public-rt"
  }
}

resource "aws_route_table_association" "elk_public_assoc" {
  subnet_id      = aws_subnet.elk_public_subnet.id
  route_table_id = aws_route_table.elk_public_rt.id
}

############################
# Security group for ELK
############################

resource "aws_security_group" "elk_sg" {
  name        = "elk-sg"
  description = "Allow SSH and ELK ports"
  vpc_id      = aws_vpc.elk_vpc.id

  # SSH from your IP / office
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]   # e.g. "0.0.0.0/0" for learning ONLY
  }

  # Elasticsearch HTTP
  ingress {
    description = "Elasticsearch"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
  #  cidr_blocks = ["your_cidr"]          # open as per your need
    cidr_blocks = ["0.0.0.0/0"]           # easy for lab, restrict later
  }

  # Kibana
  ingress {
    description = "Kibana"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]           # easy for lab, restrict later
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elk-sg"
  }
}

############################
# EC2 instance for ELK
############################

resource "aws_instance" "elk_server" {
  ami                         = var.elk_ami_id          # e.g. Ubuntu 22.04 AMI ID
  instance_type               = var.instance_type          # e.g. "t3.medium"
  subnet_id                   = aws_subnet.elk_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.elk_sg.id]
  key_name                    = var.key_name            # existing key pair in region
  associate_public_ip_address = true

  # For now, keep user_data minimal; later we will replace this with Ansible.
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              # You can keep this light and let Ansible install ELK later
              EOF

  tags = {
    Name = "elk-server"
  }
}

