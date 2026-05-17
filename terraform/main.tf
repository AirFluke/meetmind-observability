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

# Deploy the stack onto the server via SSH
resource "null_resource" "lgtm_deploy" {
  triggers = {
    install_hash = filemd5("${path.module}/../install.sh")
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/../"
    destination = "/opt/meetmind-observability"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/meetmind-observability",
      "sudo SLACK_WEBHOOK=${var.slack_webhook} bash install.sh"
    ]
  }
}

# Open required ports on AWS security group
resource "aws_security_group_rule" "grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.security_group_id
  description       = "Grafana UI"
}

resource "aws_security_group_rule" "prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = var.security_group_id
  description       = "Prometheus"
}

resource "aws_security_group_rule" "alertmanager" {
  type              = "ingress"
  from_port         = 9093
  to_port           = 9093
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = var.security_group_id
  description       = "Alertmanager"
}

resource "aws_security_group_rule" "pushgateway" {
  type              = "ingress"
  from_port         = 9091
  to_port           = 9091
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.security_group_id
  description       = "Pushgateway"
}

resource "aws_security_group_rule" "loki" {
  type              = "ingress"
  from_port         = 3100
  to_port           = 3100
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = var.security_group_id
  description       = "Loki"
}

resource "aws_security_group_rule" "tempo" {
  type              = "ingress"
  from_port         = 3200
  to_port           = 3200
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = var.security_group_id
  description       = "Tempo"
}