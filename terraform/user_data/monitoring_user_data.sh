#!/bin/bash
set -e

# ---------------------------
# Monitoring server boot script (Ubuntu 22.04)
# - Runs ONCE at instance creation (cloud-init user_data)
# - Clones repo and installs Prometheus + Alertmanager + Grafana
# ---------------------------

repo_url="${repo_url}"
slack_webhook_url="${slack_webhook_url}"
aws_region="${aws_region}"

# Basic packages we need to clone repo + download tarballs
apt-get update -y
apt-get install -y git curl ca-certificates gnupg

# Clone repo to /opt (clean and common for services)
mkdir -p /opt
cd /opt

# If re-running for any reason, remove old clone
rm -rf monitoring-stack-aws || true
git clone "${repo_url}" monitoring-stack-aws
cd monitoring-stack-aws

# Export Slack webhook so install script can inject it into config
export SLACK_WEBHOOK_URL
export AWS_REGION

# Run the install (script creates users, dirs, configs, systemd units)
bash scripts/install_monitoring_stack.sh
