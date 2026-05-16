# ─────────────────────────────────────────────────────────────────────────────
# MeetMind Observability Platform — Terraform IaC
# Provisions an Ubuntu 24.04 EC2 instance and bootstraps the full LGTM stack.
#
# One-command deployment:
#   terraform init && terraform apply -auto-approve
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

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

# ─────────────────────────────────────────────────────────────────────────────
# Data: latest Ubuntu 24.04 LTS AMI
# ─────────────────────────────────────────────────────────────────────────────
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

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Group — open only required ports
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "observability" {
  name        = "${var.project_name}-sg"
  description = "Security group for MeetMind LGTM observability stack"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Grafana
  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Alertmanager
  ingress {
    description = "Alertmanager"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Pushgateway (needed by GitHub Actions)
  ingress {
    description = "Pushgateway"
    from_port   = 9091
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Loki
  ingress {
    description = "Loki"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tempo
  ingress {
    description = "Tempo HTTP"
    from_port   = 3200
    to_port     = 3200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node Exporter
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Blackbox Exporter
  ingress {
    description = "Blackbox Exporter"
    from_port   = 9115
    to_port     = 9115
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OTel Collector — gRPC + HTTP (for instrumented services)
  ingress {
    description = "OTel Collector gRPC"
    from_port   = 4317
    to_port     = 4320
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# EC2 Instance — bootstraps via user_data (cloud-init)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_instance" "observability" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.observability.id]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    github_repo       = var.github_repo
    github_branch     = var.github_branch
    slack_webhook_url = var.slack_webhook_url
  })

  tags = {
    Name    = "${var.project_name}-server"
    Project = var.project_name
  }

  # Wait for cloud-init to finish before marking as created
  provisioner "remote-exec" {
    inline = ["cloud-init status --wait"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/${var.key_name}.pem")
      host        = self.public_ip
    }
  }
}
