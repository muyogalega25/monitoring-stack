# Monitoring Stack on AWS (Ubuntu 22.04 + systemd)

## What this creates
- 1x Monitoring EC2: Prometheus (tarball), Alertmanager (tarball), Grafana (APT)
- 2x App EC2: Node Exporter (tarball)

## Prereqs
- AWS credentials configured on Jenkins (or on your machine if running locally)
- Existing EC2 key pair name
- Slack incoming webhook URL

## Jenkins
- Create a pipeline pointing at this repo
- Run with ACTION=apply to create infra
- Run with ACTION=destroy to clean up

## Local (optional)
cd terraform
terraform init
terraform plan
terraform apply

##repo structure
monitoring-stack-aws/
├─ README.md
├─ Jenkinsfile
├─ terraform/
│  ├─ main.tf
│  ├─ variables.tf
│  ├─ outputs.tf
│  └─ user_data/
│     ├─ monitoring_user_data.sh
│     └─ app_user_data.sh
├─ scripts/
│  ├─ install_monitoring_stack.sh
│  └─ install_node_exporter.sh
├─ configs/
│  ├─ prometheus.yml
│  ├─ rules.yml
│  └─ alertmanager.yml
└─ systemd/
   ├─ prometheus.service
   ├─ alertmanager.service
   └─ node_exporter.service
