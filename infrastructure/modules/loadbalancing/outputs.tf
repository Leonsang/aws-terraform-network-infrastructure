output "alb_name" {
  description = "Nombre del Application Load Balancer"
  value       = aws_lb.main.name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN del Target Group principal"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Nombre del Target Group principal"
  value       = aws_lb_target_group.main.name
}

output "https_listener_arn" {
  description = "ARN del listener HTTPS"
  value       = aws_lb_listener.https.arn
}

output "http_listener_arn" {
  description = "ARN del listener HTTP"
  value       = aws_lb_listener.http.arn
}

output "high_latency_alarm_arn" {
  description = "ARN de la alarma de latencia alta"
  value       = aws_cloudwatch_metric_alarm.high_latency.arn
}

output "high_5xx_alarm_arn" {
  description = "ARN de la alarma de errores 5XX"
  value       = aws_cloudwatch_metric_alarm.high_5xx.arn
}

output "loadbalancer_dashboard_name" {
  description = "Nombre del dashboard de CloudWatch para el balanceador"
  value       = aws_cloudwatch_dashboard.loadbalancer.dashboard_name
} 