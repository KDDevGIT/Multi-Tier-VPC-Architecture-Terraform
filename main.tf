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
