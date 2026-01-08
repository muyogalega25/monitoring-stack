terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# Default VPC + Subnets (simple demo)
# -------------------------
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Pick one subnet deterministically (sorted) to avoid random ordering differences
locals {
  default_subnet_id = sort(data.aws_subnets.default.ids)[0]
}

# -------------------------
# Latest Ubuntu 22.04 LTS AMI (Canonical)
# -------------------------
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# -------------------------
# IAM role: allow Prometheus EC2 service discovery (DescribeInstances)
# -------------------------
data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "prom_sd_role" {
  name               = "prometheus-ec2-sd-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
}

resource "aws_iam_role_policy" "prom_sd_policy" {
  name = "prometheus-ec2-sd-policy"
  role = aws_iam_role.prom_sd_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeTags"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "prom_sd_profile" {
  name = "prometheus-ec2-sd-profile"
  role = aws_iam_role.prom_sd_role.name
}

# -------------------------
# User data templates
# -------------------------
locals {
  monitoring_user_data = templatefile("${path.module}/user_data/monitoring_user_data.sh", {
    repo_url          = var.repo_url
    slack_webhook_url = var.slack_webhook_url
    aws_region        = var.aws_region
  })

  app_user_data = templatefile("${path.module}/user_data/app_user_data.sh", {
    repo_url = var.repo_url
  })
}

# -------------------------
# Security groups
# -------------------------

# Monitoring SG: allow public access to Grafana/Prom/Alertmanager (restrict to your IP later)
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Monitoring SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App SG: allow Node Exporter ONLY from monitoring SG
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "App SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Recommended: use source_security_group_id instead of security_groups
  ingress {
    from_port                = 9100
    to_port                  = 9100
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.monitoring_sg.id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# Monitoring instance
# -------------------------
resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = local.default_subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.prom_sd_profile.name
  associate_public_ip_address = true

  user_data = local.monitoring_user_data

  tags = {
    Name = "monitoring-server"
    Role = "monitoring"
  }
}

# -------------------------
# Two app instances
# -------------------------
resource "aws_instance" "app" {
  count                       = 2
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = local.default_subnet_id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  user_data = local.app_user_data

  tags = {
    Name = "app-server-${count.index + 1}"
    Role = "app"
  }
}
