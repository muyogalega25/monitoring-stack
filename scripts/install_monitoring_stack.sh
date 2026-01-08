#!/bin/bash
set -euo pipefail

# ---------------------------
# Installs Prometheus + Alertmanager (tarballs) + Grafana (APT) on Ubuntu 22.04
# - Uses systemd services
# - Prometheus uses EC2 Service Discovery to find app instances by tag Role=app
# - Alertmanager sends alerts to Slack using an incoming webhook
# ---------------------------

PROM_VERSION="2.52.0"
AM_VERSION="0.27.0"
ARCH="linux-amd64"

# Slack webhook is passed from user_data as an env var
: "${SLACK_WEBHOOK_URL:?Missing SLACK_WEBHOOK_URL environment variable}"
: "${AWS_REGION:?Missing AWS_REGION environment variable}"

# --- Create service users ---
id -u prometheus >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin prometheus
id -u alertmanager >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin alertmanager

# --- Create directories ---
mkdir -p /etc/prometheus /var/lib/prometheus
mkdir -p /etc/alertmanager /var/lib/alertmanager

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager

# --- Install Prometheus (tarball) ---
cd /tmp
PROM_TARBALL="prometheus-${PROM_VERSION}.${ARCH}.tar.gz"
curl -fsSLO "https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/${PROM_TARBALL}"
tar -xzf "${PROM_TARBALL}"

cp "prometheus-${PROM_VERSION}.${ARCH}/prometheus" /usr/local/bin/prometheus
cp "prometheus-${PROM_VERSION}.${ARCH}/promtool" /usr/local/bin/promtool
chmod 755 /usr/local/bin/prometheus /usr/local/bin/promtool
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# --- Install Alertmanager (tarball) ---
AM_TARBALL="alertmanager-${AM_VERSION}.${ARCH}.tar.gz"
curl -fsSLO "https://github.com/prometheus/alertmanager/releases/download/v${AM_VERSION}/${AM_TARBALL}"
tar -xzf "${AM_TARBALL}"

cp "alertmanager-${AM_VERSION}.${ARCH}/alertmanager" /usr/local/bin/alertmanager
cp "alertmanager-${AM_VERSION}.${ARCH}/amtool" /usr/local/bin/amtool
chmod 755 /usr/local/bin/alertmanager /usr/local/bin/amtool
chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool

# --- Copy configs from repo into /etc ---
# 1) Prometheus config + rules
cp configs/prometheus.yml /etc/prometheus/prometheus.yml
cp configs/rules.yml /etc/prometheus/rules.yml

# Inject region into prometheus config (simple replace)
sed -i "s|__AWS_REGION__|${AWS_REGION}|g" /etc/prometheus/prometheus.yml

chown prometheus:prometheus /etc/prometheus/prometheus.yml /etc/prometheus/rules.yml

# 2) Alertmanager config (inject Slack webhook)
cp configs/alertmanager.yml /etc/alertmanager/alertmanager.yml
sed -i "s|__SLACK_WEBHOOK_URL__|${SLACK_WEBHOOK_URL}|g" /etc/alertmanager/alertmanager.yml
chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

# --- Install systemd units ---
cp systemd/prometheus.service /etc/systemd/system/prometheus.service
cp systemd/alertmanager.service /etc/systemd/system/alertmanager.service

# --- Grafana via APT (official repo) ---
apt-get update -y
apt-get install -y apt-transport-https software-properties-common

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  > /etc/apt/sources.list.d/grafana.list

apt-get update -y
apt-get install -y grafana

# --- Enable + start services ---
systemctl daemon-reload
systemctl enable --now prometheus
systemctl enable --now alertmanager
systemctl enable --now grafana-server

# --- Quick status for cloud-init logs ---
systemctl --no-pager status prometheus || true
systemctl --no-pager status alertmanager || true
systemctl --no-pager status grafana-server || true
