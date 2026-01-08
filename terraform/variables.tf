variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 Key Pair name for SSH"
}

variable "repo_url" {
  type        = string
  description = "Git repo URL to clone on instances"
}

variable "slack_webhook_url" {
  type        = string
  description = ""
  sensitive   = true
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
