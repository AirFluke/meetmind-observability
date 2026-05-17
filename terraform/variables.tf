variable "aws_region" {
  description = "AWS region to deploy monitoring server"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "VPC ID to deploy monitoring server into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the monitoring server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for monitoring server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into monitoring server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_server_ip" {
  description = "Public IP of the application server to monitor"
  type        = string
  default     = "13.63.206.183"
}

variable "app_server_security_group_id" {
  description = "Security group ID of the application server (to open Node Exporter port)"
  type        = string
}

variable "slack_webhook" {
  description = "Slack webhook URL for Alertmanager notifications"
  type        = string
  sensitive   = true
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  default     = "MeetMind@2024"
  sensitive   = true
}

variable "repo_url" {
  description = "GitHub repo URL to clone on the monitoring server"
  type        = string
  default     = "https://github.com/AirFluke/meetmind-observability.git"
}
