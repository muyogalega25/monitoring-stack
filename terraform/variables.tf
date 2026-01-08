variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into"
  default     = "us-east-2"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 Key Pair name for SSH access"
}

variable "repo_url" {
  type        = string
  description = "Git repository URL to clone on EC2 instances"
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack Incoming Webhook URL for Alertmanager"
  sensitive   = true
}

variable "monitoring_instance_type" {
  type        = string
  description = "EC2 instance type for monitoring server (Free Tier eligible)"
  default     = "t3.micro"
}

variable "app_instance_type" {
  type        = string
  description = "EC2 instance type for app servers (Free Tier eligible)"
  default     = "t3.micro"
}

variable "app_instance_count" {
  type        = number
  description = "Number of app servers to create"
  default     = 2
}
