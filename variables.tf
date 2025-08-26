# Tuneable Variables

# Empty Project Message
variable "project" {
    description = "Project prefix used in names and tags"
    type = string
    default = "mt-vpc"
    validation {
        condition = length(var.project) > 0
        error_message = "Cannot have empty project"
    }
}

# Environments
variable "env" {
    description = "Environment Tag (dev, stage, prod)"
    type = string
    default = "dev"
}

# Regions
variable "aws_region" {
    description = "AWS Region to Deploy"
    type = string
    default = "us-east-1"
}

# VPC CIDR Check
variable "vpc_cidr" {
    description = "CIDR for VPC"
    type = string
    default = "10.0.0.0/20"

    validation {
        condition = can(cidrhost(var.vpc_cidr, 0))
        error_message = "variable vpc_cidr must be a valid CIDR"
    }
}

# Public IP CIDR Check
variable "my_ip_cidr" {
    description = "Verify Public IP CIDR form to allow SSH to Bastion" #(x.x.x.x/32)
    type = string

    # Fails if incorrect CIDR notation
    validation {
        condition = can(cidrhost(var.my_ip_cidr, 0))
        error_message = "variable my_ip_cidr must be a valid CIDR e.g XXX.X.XXX.X/32"
    }
}

# Bastion Instance Type 
variable "bastion_instance_type" {
    description = "EC2 instance type for Bastion"
    type = string
    default = "t3.micro"
}

# Database Username
variable "db_username" {
    description = "Master Password for RDS Postgres"
    type = string
    default = "appuser"

    validation {
        condition = length(var.db_username) >= 3
        error_message = "Username must be at least 3 characters"
    }
}

# Database Password
variable "db_password" {
    description = "Master Password for RDS Postgres"
    type = string
    sensitive = true

    validation {
        condition = length(var.db_password) >= 8
        error_message = "Password must be at least 8 characters"
    }
}

# Optional Toggles

# Enable Multi-Availability Zones
variable "db_multi_az" {
    description = "Enable Multi-AZ for RDS" # Higher Cost
    type = bool
    default = false
}

