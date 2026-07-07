#############################################
# AWS Provider Configuration
# Project : Multi-AZ Disaster Recovery Simulation
# Author  : Arnold Bernard
#############################################

terraform {
  required_version = ">= 1.13.0"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

#############################################
# AWS Provider
#############################################

provider "aws" {

  region  = var.aws_region
  profile = var.aws_profile

  default_tags {

    tags = {

      Project     = "DR-Simulation"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Arnold Bernard"

    }

  }

}