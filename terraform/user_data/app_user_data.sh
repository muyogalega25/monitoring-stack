#!/bin/bash
set -e

# ---------------------------
# App server boot script (Ubuntu 22.04)
# - Runs ONCE at instance creation (cloud-init user_data)
# - Installs Node Exporter as a systemd service
# ---------------------------

REPO_URL="${repo_url}"

apt-get update -y
apt-get install -y git curl ca-certificates

mkdir -p /opt
cd /opt

rm -rf monitoring-stack-aws || true
git clone "${REPO_URL}" monitoring-stack-aws
cd monitoring-stack-aws

bash scripts/install_node_exporter.sh
