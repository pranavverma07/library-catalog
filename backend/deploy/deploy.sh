#!/bin/bash
# Fetches the latest backend build from S3, wires up DB credentials from
# Secrets Manager, and (re)starts the systemd service. Runs identically at
# instance first-boot (invoked from Terraform user_data) and on every
# subsequent redeploy (invoked via SSM Run Command from GitHub Actions) -
# this file is the single source of truth for "how the app gets onto a box".
set -euo pipefail

: "${DEPLOY_BUCKET:?DEPLOY_BUCKET is required}"
: "${AWS_REGION:?AWS_REGION is required}"
: "${DB_SECRET_ARN:?DB_SECRET_ARN is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:?DB_PORT is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${APP_PORT:?APP_PORT is required}"

command -v unzip >/dev/null || dnf install -y unzip
command -v jq >/dev/null || dnf install -y jq

APP_DIR=/opt/library-catalog
RELEASE_DIR="$APP_DIR/release-$(date +%s)"

echo "Fetching latest app artifact from s3://${DEPLOY_BUCKET}/backend/latest.zip"
mkdir -p "$RELEASE_DIR"
aws s3 cp "s3://${DEPLOY_BUCKET}/backend/latest.zip" /tmp/app.zip --region "$AWS_REGION"
unzip -oq /tmp/app.zip -d "$RELEASE_DIR"

echo "Fetching DB credentials from Secrets Manager"
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --region "$AWS_REGION" \
  --query SecretString --output text)
DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')

# printf, not a heredoc: the password can contain $ or backticks, and a
# heredoc without a quoted delimiter would let the shell re-interpret those.
ENV_FILE="$RELEASE_DIR/.env"
: > "$ENV_FILE"
printf 'PGHOST=%s\n' "$DB_HOST" >> "$ENV_FILE"
printf 'PGPORT=%s\n' "$DB_PORT" >> "$ENV_FILE"
printf 'PGUSER=%s\n' "$DB_USER" >> "$ENV_FILE"
printf 'PGPASSWORD=%s\n' "$DB_PASS" >> "$ENV_FILE"
printf 'PGDATABASE=%s\n' "$DB_NAME" >> "$ENV_FILE"
printf 'PGSSL=true\n' >> "$ENV_FILE"
printf 'PORT=%s\n' "$APP_PORT" >> "$ENV_FILE"
chmod 600 "$ENV_FILE"
chown -R ec2-user:ec2-user "$RELEASE_DIR"

ln -sfn "$RELEASE_DIR" "$APP_DIR/current"

# Clean up old releases, keep the 2 most recent for quick rollback.
ls -1dt "$APP_DIR"/release-* 2>/dev/null | tail -n +3 | xargs -r rm -rf

cat > /etc/systemd/system/library-catalog.service <<'UNIT'
[Unit]
Description=Library Catalog API
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/library-catalog/current
EnvironmentFile=/opt/library-catalog/current/.env
ExecStart=/usr/bin/node src/index.js
Restart=on-failure
RestartSec=5
User=ec2-user

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable library-catalog
systemctl restart library-catalog

echo "Deploy complete: $RELEASE_DIR"
