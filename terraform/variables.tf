variable "aws_region" {
  description = "AWS region where ELK infra will be created"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the ELK VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the ELK server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Existing AWS key pair name (used for SSH into ELK server)"
  type        = string
}

variable "elk_ami_id" {
  description = "AMI ID for the ELK EC2 instance (e.g., Ubuntu 22.04 in your region)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the ELK server"
  type        = string
  default     = "0.0.0.0/0" # for labs; tighten later
}

