#!/bin/bash
set -euo pipefail

########################################################################
# 0. Bootstrap
########################################################################

ENVIRONMENT="${ENVIRONMENT}"   # injected by Terraform: dev | prod

echo "===== User data start (env=${ENVIRONMENT}) ====="

export DEBIAN_FRONTEND=noninteractive

########################################################################
# 1. Expand root disk (safe, idempotent)
########################################################################

growpart /dev/nvme0n1 1 || true
resize2fs /dev/nvme0n1p1 || true

########################################################################
# 2. Resolve environment-specific paths (SINGLE SOURCE OF TRUTH)
########################################################################

if [ "${ENVIRONMENT}" = "prod" ]; then
  APP_BASE_DIR="/opt/backend"
  LOG_DIR="/opt/backend.log"
else
  APP_BASE_DIR="/home/ubuntu/backend"
  LOG_DIR="/home/ubuntu/backend.log"
fi

########################################################################
# 3. Global environment variables (for Docker + systemd)
########################################################################

cat >/etc/environment <<EOF
ENVIRONMENT=${ENVIRONMENT}
APP_BASE_DIR=\$APP_BASE_DIR
PYTHONUNBUFFERED=1
EOF

########################################################################
# 4. Base OS packages
########################################################################

apt-get update -y
apt-get upgrade -y

apt-get install -y \
  ca-certificates \
  curl \
  unzip \
  git \
  gnupg \
  lsb-release \
  software-properties-common \
  build-essential \
  python3 \
  python3-pip \
  python3-venv

########################################################################
# 5. Python 3.11 (deterministic, no guessing)
########################################################################

add-apt-repository ppa:deadsnakes/ppa -y
apt-get update -y

apt-get install -y \
  python3.11 \
  python3.11-dev \
  python3.11-venv

update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

########################################################################
# 6. Docker + compose plugin
########################################################################

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | bash
fi

apt-get install -y docker-compose-plugin

systemctl enable docker
systemctl start docker

# Allow ubuntu user to run docker (non-interactive safe)
if id ubuntu >/dev/null 2>&1; then
  usermod -aG docker ubuntu || true
fi

########################################################################
# 7. AWS CLI
########################################################################

if ! command -v aws >/dev/null 2>&1; then
  apt-get install -y awscli
fi

########################################################################
# 8. SSM Agent (deb, not snap)
########################################################################

if ! systemctl is-active --quiet amazon-ssm-agent; then
  curl -o /tmp/amazon-ssm-agent.deb \
    https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
  dpkg -i /tmp/amazon-ssm-agent.deb || apt-get install -f -y
  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent
fi

########################################################################
# 9. Swap (memory safety for Docker + Chrome)
########################################################################

if ! grep -q "swapfile" /etc/fstab; then
  echo "Creating 6G swap..."
  fallocate -l 6G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=6144
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0 # swapfile" >> /etc/fstab
fi

########################################################################
# 10. Chrome + ChromeDriver (Selenium / scraping)
########################################################################

if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /usr/share/keyrings/google-linux-signing-keyring.gpg

  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] \
    http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list

  apt-get update -y
fi

apt-get install -y google-chrome-stable xvfb fonts-liberation

CHROME_MAJOR="$(google-chrome --version | awk '{print $3}' | cut -d. -f1 || echo 0)"
if [ "\$CHROME_MAJOR" != "0" ]; then
  CHROMEDRIVER_VERSION="$(curl -sS https://chromedriver.storage.googleapis.com/LATEST_RELEASE_\$CHROME_MAJOR)"
  curl -sS -o /tmp/chromedriver.zip \
    https://chromedriver.storage.googleapis.com/\$CHROMEDRIVER_VERSION/chromedriver_linux64.zip
  unzip -o /tmp/chromedriver.zip -d /usr/local/bin
  chmod +x /usr/local/bin/chromedriver
fi

########################################################################
# 11. Application directories (Docker volumes)
########################################################################

echo "Creating application directories under \$APP_BASE_DIR"

mkdir -p "\$APP_BASE_DIR" 

chown -R ubuntu:ubuntu "\$APP_BASE_DIR" || true
chmod 755 "\$APP_BASE_DIR"

########################################################################
# 12. CloudWatch Logs agent
########################################################################

if ! dpkg -s amazon-cloudwatch-agent >/dev/null 2>&1; then
  curl -o /tmp/amazon-cloudwatch-agent.deb \
    https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y
fi

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/company/syslog",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "\$LOG_DIR/backend.log",
            "log_group_name": "/company/backend",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s || true

########################################################################
# 13. systemd service (Docker-managed backend)
########################################################################

cat >/etc/systemd/system/backend.service <<EOF
[Unit]
Description=Backend Docker container
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=5
ExecStart=/usr/bin/docker start -a backend
ExecStop=/usr/bin/docker stop backend

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable backend.service || true

########################################################################
# 14. Final marker
########################################################################

touch /var/log/user-data.ok

echo "===== User data finished (env=${ENVIRONMENT}) ====="
