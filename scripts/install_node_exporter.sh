#!/bin/bash
set -euo pipefail

# ---------------------------
# Installs Node Exporter (tarball) on Ubuntu 22.04
# - Creates a non-login user
# - Installs binary to /usr/local/bin
# - Sets up systemd service
# ---------------------------

NODE_EXPORTER_VERSION="1.7.0"
ARCH="linux-amd64"
TARBALL="node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${TARBALL}"

# 1) Create a dedicated user (no shell, safer for services)
id -u node_exporter >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter

# 2) Download + install the binary
cd /tmp
curl -fsSLO "${URL}"
tar -xzf "${TARBALL}"
cp "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" /usr/local/bin/node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter
chmod 755 /usr/local/bin/node_exporter

# 3) Install systemd unit
cp systemd/node_exporter.service /etc/systemd/system/node_exporter.service

# 4) Start service now + on boot
systemctl daemon-reload
systemctl enable --now node_exporter

# 5) Quick status (helps debugging in cloud-init logs)
systemctl --no-pager status node_exporter || true
