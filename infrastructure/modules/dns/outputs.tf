output "zone_id" {
  description = "ID de la zona DNS"
  value       = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
}

output "zone_name" {
  description = "Nombre de la zona DNS"
  value       = var.create_zone ? aws_route53_zone.main[0].name : null
}

output "zone_name_servers" {
  description = "Name servers de la zona DNS"
  value       = var.create_zone ? aws_route53_zone.main[0].name_servers : null
}

output "certificate_arn" {
  description = "ARN del certificado SSL/TLS"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain_name" {
  description = "Nombre de dominio del certificado"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Estado del certificado"
  value       = aws_acm_certificate.main.status
}

output "domain_name" {
  description = "Nombre de dominio configurado"
  value       = local.domain_name
}

output "alb_record_name" {
  description = "Nombre del registro A para el ALB"
  value       = var.create_alb_record ? aws_route53_record.alb[0].name : null
}

output "www_record_name" {
  description = "Nombre del registro CNAME para www"
  value       = var.create_www_record ? aws_route53_record.www[0].name : null
}

output "mx_records" {
  description = "Registros MX configurados"
  value       = var.create_mx_records ? aws_route53_record.mx[0].records : null
}

output "spf_record" {
  description = "Registro SPF configurado"
  value       = var.create_spf_record ? aws_route53_record.spf[0].records : null
}

output "dmarc_record" {
  description = "Registro DMARC configurado"
  value       = var.create_dmarc_record ? aws_route53_record.dmarc[0].records : null
}

output "health_check_id" {
  description = "ID del health check"
  value       = var.create_health_check ? aws_route53_health_check.main[0].id : null
}

output "health_check_status" {
  description = "Estado del health check"
  value       = var.create_health_check ? aws_route53_health_check.main[0].status : null
}

output "health_check_alarm_arn" {
  description = "ARN de la alarma del health check"
  value       = var.create_health_check ? aws_cloudwatch_metric_alarm.health_check[0].arn : null
}

output "dns_dashboard_name" {
  description = "Nombre del dashboard de CloudWatch para DNS"
  value       = aws_cloudwatch_dashboard.dns.dashboard_name
} 