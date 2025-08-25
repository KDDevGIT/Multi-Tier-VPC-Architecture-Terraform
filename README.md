# AWS Multi-Tier VPC (Terraform)
## Overview
This project provisions a secure VPC with public and private subnets, an EC2 bastion host, and an RDS instance using Terraform.  
It demonstrates AWS networking, security groups vs NACLs, and Infrastructure as Code best practices.

## Skills & Tools
- AWS VPC, EC2, RDS, IAM, Route Tables
- Terraform (remote backend with S3 + DynamoDB)
- Linux (bastion host access)
- Networking (private/public subnet design)

## Deployment
```bash
git clone https://github.com/kyler/aws-vpc-terraform
cd aws-vpc-terraform
terraform init
terraform apply
