# ─────────────────────────────────────────────────────────────────────────────
# Outputs — displayed after `terraform apply`
# ─────────────────────────────────────────────────────────────────────────────

output "server_public_ip" {
  description = "Public IP of the observability server"
  value       = aws_instance.observability.public_ip
}

output "grafana_url" {
  description = "Grafana URL (default login: admin/admin)"
  value       = "http://${aws_instance.observability.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${aws_instance.observability.public_ip}:9090"
}

output "alertmanager_url" {
  description = "Alertmanager URL"
  value       = "http://${aws_instance.observability.public_ip}:9093"
}

output "pushgateway_url" {
  description = "Pushgateway URL (used by GitHub Actions)"
  value       = "http://${aws_instance.observability.public_ip}:9091"
}

output "loki_url" {
  description = "Loki URL"
  value       = "http://${aws_instance.observability.public_ip}:3100"
}

output "tempo_url" {
  description = "Tempo URL"
  value       = "http://${aws_instance.observability.public_ip}:3200"
}

output "ssh_command" {
  description = "SSH into the server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.observability.public_ip}"
}

output "bootstrap_log" {
  description = "Command to view bootstrap progress"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.observability.public_ip} 'tail -f /var/log/meetmind-bootstrap.log'"
}
