# Backend CD workflow uploads app.zip + deploy.sh here; EC2 instances (via
# their instance role) pull from this bucket on boot and on every redeploy.
# This is the hand-off point between "GitHub Actions built something" and
# "an EC2 instance is running it" - no SSH, no CodeDeploy agent required.
resource "aws_s3_bucket" "deploy_artifacts" {
  bucket = "${var.project}-deploy-artifacts-905418054237"
}

resource "aws_s3_bucket_versioning" "deploy_artifacts" {
  bucket = aws_s3_bucket.deploy_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "deploy_artifacts" {
  bucket                  = aws_s3_bucket.deploy_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
