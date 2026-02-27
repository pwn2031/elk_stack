aws_region        = "ap-south-1"

vpc_cidr          = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

instance_type     = "t3.medium"

# Replace with an EXISTING key pair name in ap-south-1
key_name          = "pawan-elk-key"

# Replace with a valid Ubuntu 22.04 AMI ID in ap-south-1
elk_ami_id        = "ami-0ff91eb5c6fe7cc86"

# For lab only; later restrict to your IP (e.g. \"x.x.x.x/32\")
allowed_ssh_cidr  = "0.0.0.0/0"

