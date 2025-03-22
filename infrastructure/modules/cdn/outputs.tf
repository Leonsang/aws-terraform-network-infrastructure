output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "Nombre de dominio de CloudFront"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "waf_web_acl_id" {
  description = "ID del Web ACL de WAF"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "ARN del Web ACL de WAF"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_name" {
  description = "Nombre del Web ACL de WAF"
  value       = aws_wafv2_web_acl.main.name
}

output "waf_ip_set_id" {
  description = "ID del conjunto de IPs bloqueadas"
  value       = length(var.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked[0].id : null
}

output "waf_ip_set_arn" {
  description = "ARN del conjunto de IPs bloqueadas"
  value       = length(var.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked[0].arn : null
}

output "waf_blocked_requests_alarm_arn" {
  description = "ARN de la alarma de solicitudes bloqueadas"
  value       = aws_cloudwatch_metric_alarm.waf_blocked_requests.arn
}

output "dashboard_name" {
  description = "Nombre del dashboard de CloudWatch"
  value       = aws_cloudwatch_dashboard.cdn_waf.dashboard_name
} 