# AWS Provider and Version
terraform {
    # modern Terraform version
    required_version = ">= 1.6.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            # AWS Provicer v5 
            version = "~> 5.0"
        }
    }
    # Remote State Backend
}