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

# Internet Gateway ID
output "internet_gateway_id" {
    value = aws_internet_gateway.igw.id
    description = "Internet Gateway ID"
}

# NAT Gateway ID
output "nat_gateway_id" {
    value = aws_nat_gateway.nat.id
    description = "NAT Gateway ID. (Singe NAT Default)"
}

# Bastion Instance ID
output "bastion_instance_id" {
    value = aws_instance.bastion.id
    description = "Bastion EC2 Instance ID"
}

# Bastion Public IP
output "bastion_public_ip" {
    value = aws_instance.bastion.map_public_ip
    description = "Bastion Public IP (Accessible via SSM)"
}

