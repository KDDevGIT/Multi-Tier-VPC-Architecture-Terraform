# Core Outputs

# VPC ID
output "vpc_id" {
    value = aws_vpc.main.id
    description = "Created VPC ID"
}

