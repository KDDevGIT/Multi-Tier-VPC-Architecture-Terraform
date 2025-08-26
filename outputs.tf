# Core Outputs

# VPC ID
output "vpc_id" {
    value = aws_vpc.main.id
    description = "Created VPC ID"
}

# VPC CIDR 
output "vpc_cidr" {
    value = aws_vpc.main.cidr_block
    description = "VPC CIDR"
}

# Public Subnet ID
output "public_subnet_ids" {
    value = [for s in aws_subnet.public : s.id]
    description = "IDs of Public Subnets"
}

# Private Subnet ID
output "private_subnet_ids" {
    value = [for s in aws_subnet.public : s.id]
    description = "IDs of Private Subnets"
}

