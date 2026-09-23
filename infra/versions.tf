terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "library-catalog-tfstate-905418054237"
    key          = "library-catalog/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # native S3 locking (TF 1.10+) - no DynamoDB table needed
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "library-catalog"
    }
  }
}
