terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# One-time bootstrap: creates the S3 bucket that holds Terraform's own remote
# state for the real infra (infra/). State locking uses Terraform's native S3
# lockfile support (TF 1.10+) via use_lockfile in the backend block, so no
# separate DynamoDB table is needed. This config has no backend of its own
# (state for THIS config stays local) because it must exist before a remote
# backend can. Apply this once, manually, with your personal AWS credentials.

resource "aws_s3_bucket" "tfstate" {
  bucket = "library-catalog-tfstate-905418054237"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" {
  value = aws_s3_bucket.tfstate.id
}
