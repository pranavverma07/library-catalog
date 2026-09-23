#!/bin/bash
# Runs once when an instance boots (first launch, or ASG replacing an
# unhealthy/terminated instance). Installs the runtime, then delegates the
# actual app install/start to deploy.sh pulled fresh from S3 - so a brand new
# instance always ends up running whatever was most recently deployed,
# without needing a custom AMI baked per release.
set -euo pipefail

# Amazon Linux 2023 ships AWS CLI v2 preinstalled; only unzip/jq are missing.
dnf install -y unzip jq
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

export DEPLOY_BUCKET="${deploy_bucket}"
export AWS_REGION="${aws_region}"
export DB_SECRET_ARN="${db_secret_arn}"
export DB_HOST="${db_host}"
export DB_PORT="${db_port}"
export DB_NAME="${db_name}"
export APP_PORT="${app_port}"

aws s3 cp "s3://${deploy_bucket}/backend/deploy.sh" /tmp/deploy.sh --region "${aws_region}"
chmod +x /tmp/deploy.sh
/tmp/deploy.sh
