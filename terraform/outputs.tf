output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "prometheus_url" {
  value = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "alertmanager_url" {
  value = "http://${aws_instance.monitoring.public_ip}:9093"
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}
