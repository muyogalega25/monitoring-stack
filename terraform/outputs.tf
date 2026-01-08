output "monitoring_public_ip" {
  description = "Public IP of the monitoring server"
  value       = aws_instance.monitoring.public_ip
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "alertmanager_url" {
  description = "Alertmanager UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:9093"
}

output "app_private_ips" {
  description = "Private IPs of all app servers"
  value       = aws_instance.app[*].private_ip
}
