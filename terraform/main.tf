terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "app_region"
  region = "eu-north-1"
}

# ── Data: get latest Ubuntu 24.04 AMI automatically ──────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Data: Fetch your existing, locked Elastic IP address ─────────────────────
data "aws_eip" "monitoring" {
  public_ip = "44.216.66.165"
}

# ── Security group for monitoring server ─────────────────────────────────────
resource "aws_security_group" "monitoring" {
  name        = "meetmind-monitoring-sg"
  description = "Security group for MeetMind monitoring server"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH"
  }

  # Grafana UI
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana"
  }

  # Prometheus UI
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "Prometheus"
  }

  # Alertmanager
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "Alertmanager"
  }

  # Pushgateway
  ingress {
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Pushgateway - GitHub Actions needs this"
  }

  # OTel collector - receives traces from app server
  ingress {
    from_port   = 4319
    to_port     = 4320
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OTel collector OTLP gRPC and HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name    = "meetmind-monitoring-sg"
    Project = "meetmind-observability"
  }
}

# ── EC2 monitoring server ─────────────────────────────────────────────────────
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  subnet_id              = var.subnet_id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # Cloud-init: install git, clone repo, run install.sh
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    app_server_ip    = var.app_server_ip
    slack_webhook    = var.slack_webhook
    repo_url         = var.repo_url
    grafana_password = var.grafana_password
  })

  tags = {
    Name    = "meetmind-monitoring"
    Project = "meetmind-observability"
  }
}

# ── Associate the existing EIP with your newly built EC2 instance ────────────
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.monitoring.id
  allocation_id = data.aws_eip.monitoring.id
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "monitoring_server_ip" {
  value       = data.aws_eip.monitoring.public_ip
  description = "Public IP of the monitoring server"
}

output "grafana_url" {
  value       = "http://${data.aws_eip.monitoring.public_ip}:3000"
  description = "Grafana dashboard URL"
}

output "prometheus_url" {
  value       = "http://${data.aws_eip.monitoring.public_ip}:9090"
  description = "Prometheus URL"
}

output "ssh_command" {
  value       = "ssh -i ${var.key_name}.pem ubuntu@${data.aws_eip.monitoring.public_ip}"
  description = "SSH command to connect to monitoring server"
}