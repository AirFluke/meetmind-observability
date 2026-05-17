variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "server_ip" {
  description = "Public IP of the server"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for the server"
  type        = string
  default     = "ubuntu"
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/your-key.pem"
}

variable "security_group_id" {
  description = "AWS security group ID attached to the server"
  type        = string
}

variable "slack_webhook" {
  description = "Slack webhook URL for alertmanager"
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to access internal ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}