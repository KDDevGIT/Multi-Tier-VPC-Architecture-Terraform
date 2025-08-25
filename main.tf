# AWS Provider and Version
terraform {
    # Modern Terraform version
    required_version = ">= 1.6.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            # AWS Provider v5 
            version = "~> 5.0"
        }
    }
    # Remote State Backend
}

# Dynamic region
provider "aws" {
    region = var.aws_region
}

# Data Sources
# Fetch current availability Zones
# Multiple subnets for High availability
data "aws_availability_zones" "available" {
    state = "available"
}

# Linux Bastion Host 
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"]
    }
}

# Networking
# Includes Subnets, Gateways, and Routes

# VPC with DNS Support (CIDR)
# Default CIDR is 10.0.0.0/20
resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "${var.project}-vpc"
        Env  = var.env
    }
}

# Internet Gateway (Public, Inbound/Outbound)
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.vpc_id

    tags = {
        Name = "${var.project}-igw"
    }
}

# Mutliple Availability Zones 
# 2 Public and 2 Private Subnets for failover

# Public Subnet(s) (Dynamic IP)
# Split VPC CIDR into chunks
resource "aws_subnet" "public" {
    count = 2
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(var.vpc_cidr,4,count.index) #10.0.0.0/24, 10.0.1.0/24....
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.project}-public-${count.index + 1}"
        Tier = "public"
    }
}

# Private Subnet(s) (No Public IP)
# Avoid overlapping with public subnets
resource "aws_subnet" "private" {
    count = 2
    vpc_id = aws_vpc.main.id
    cidr_block = cidrsubnet(var.vpc_cidr,4,count.index + 8) #10.0.8.0/24, 10.0.9.0/24...
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name = "${var.project}-private-${count.index + 1}"
        Tier = "private"
    }
}

# NAT Elastic IP for for Private Subnet(s)
# Outbound Only Internet Access
resource "aws_eip" "nat" {
    domain = "vpc"
    tags = {Name = "${var.project}-nat-eip"}
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id #NAT in first public subnet
    depends_on = [aws_internet_gateway.igw] #Ensures Gateway before NAT creation

    tags = {Name = "${var.project}-nat"}
}

# Public Route Table 
# Default route to Internet via Internet Gateway
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id 
    }
    tags = {Name = "${var.project}-public-rt"}
}

# Public Route Table Association
# Public Subnet -> Public Route Table
resource "aws_route_table_association" "public_assoc" {
    count = length(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

# Private Route Table
# Can reach internet without exposure
# Routes to NAT for egress
resouece "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
    tags = {Name = "${var.project}-private-rt"}
}

# Private Route Table Association
# Private Subnet -> Private Route Table
resource "aws_route_table_association" "private_assoc" {
    count = length(aws_subnet.private)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}

# Security Group Configuration

# Bastion (Jump) Security Group
# Allows SSH on Public IP Only (var.my_ip_cidr)
# Egress (exit) only to reach internet
resource "aws_security_group" "bastion_sg" {
    name = "${var.project}-bastion-sg"
    description = "SSH from Public IP"
    vpc_id = aws_vpc.main.id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip_cidr] # Public IP        
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {Name = "${var.project}-bastion-sg"}
}

# Application Load Balance Security Group (App Tier)
# Allows HTTP Port 80 from anywhere
# Egress open for updates
resource "aws_security_group" "app_sg" {
    name = "${var.project}-app-sg"
    vpc_id = aws_vpc.main.id
    description = "App Tier"

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {Name = "${var.project}-app-sg"}
}

# Database Security Group
# Example Used: PostgreSQL Port 5432
# Inbound only for AppTier SG and Bastion SG (admin)
# No public ingress allowed
resource "aws_security_group" "db_sg" {
    name = "${var.project}-db-sg"
    vpc_id = aws_vpc.main.id
    description = "DB Tier"

    ingress {
        description = "PostgreSQL from App SG or Bastion SG"
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [aws_security_group.app_sg.id, aws_security_group.bastion_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {Name = "${var.project}-db-sg"}
}

# Bastion Host for Public Subnet(s)
# Uses AWS Systems Manager (SSM)
# Managed policy can be applied per IAM role/Instance Profile.
resource "aws_iam_role" "ssm_role" {
    name = "${var.project}-bastion-ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {Service = "ec2.amazonaws.com"}
        }]
    })
}

# Grant SSM agent permissions for Session Manager
resource "aws_iam_role_policy_attachment" "ssm_core" {
role = aws_iam_role.ssm_role.name
policy_arn = "arn:aws:iam:aws:policy/AmazonSSMManagedInstanceCore"
}

# Bind role to EC2 Instance
resource "aws_iam_instance_profile" "ssm_profile" {
    name = "${var.project}-bastion-ssm-profile"
    role = aws_iam_role.ssm_role.name
}

# Bastion EC2 instance in Public Subnet[0]
# Public IP 
# Prefer Session Manager over SSH
resource "aws_instance" "bastion" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.bastion_instance_type
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    associate_public_ip_address = true
    aws_iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

    # User script on boot for tools, message updates, etc.
    user_data = file("${path.module}/userdata/bastion.sh")

    tags = {Name = "${var.project}-bastion"}
}

# Database Instance (PostgreSQL)
# Only allowed in Private Subnets
# Limited access to AppTier SG and Bastion SG

# Group private subnets for RDS Placement
resource "aws_db_subnet_group" "db_subnets" {
    name = "${var.project}-db-subnets"
    subnet_ids = [for s in aws_subnet.private : s.id]

    tags = {Name = "${var.project}-db-subnets"}
}

# Small PostgresSQL Instance for Demos
# Limited SG Contact to AppTier SG and Bastion SG
# Private Only
# Note: multi_az = true allows for failover but is more costly.
resource "aws_db_instance" "postgres" {
    identifier = "${var.project}-postgres"
    engine = "postgres"
    engine_version = "16.3"
    instance_class = "db.t3.micro"
    allocated_storage = 20

    aws_db_subnet_group_name = aws_db_subnet_group.db_subnets.name
    vpc_security_group_ids = [aws_security_group.db_sg.id]

    username = var.db_username 
    password = var.db_password
    publicly_accessible = false
    multi_az = false
    deletion_protection = false
    backup_retention_period = 7
    skip_final_snapshot = true

    tags = {Name = "${var.project}-postgres"}
}











