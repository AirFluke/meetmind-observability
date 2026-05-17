variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type — t3.medium recommended for the full LGTM stack"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (restrict to your IP in production)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for Alertmanager notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "project_name" {
  description = "Project name used for tagging resources"
  type        = string
  default     = "meetmind-observability"
}

variable "github_repo" {
  description = "GitHub repository URL to clone on the server"
  type        = string
  default     = "https://github.com/AirFluke/meetmind-observability.git"
}

variable "github_branch" {
  description = "Branch to checkout after cloning"
  type        = string
  default     = "main"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}
