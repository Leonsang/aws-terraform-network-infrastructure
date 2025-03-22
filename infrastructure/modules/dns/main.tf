locals {
  domain_name = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"
}

# Zona DNS pública
resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0
  name  = local.domain_name

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-zone-${var.environment}"
    }
  )
}

# Certificado SSL/TLS
resource "aws_acm_certificate" "main" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method        = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-cert-${var.environment}"
    }
  )
}

# Registros de validación del certificado
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Validación del certificado
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Registro A para el ALB
resource "aws_route53_record" "alb" {
  count   = var.create_alb_record ? 1 : 0
  zone_id = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id               = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Registro CNAME para www
resource "aws_route53_record" "www" {
  count   = var.create_www_record ? 1 : 0
  zone_id = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
  name    = "www.${local.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [local.domain_name]
}

# Registros MX para correo
resource "aws_route53_record" "mx" {
  count   = var.create_mx_records ? 1 : 0
  zone_id = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
  name    = local.domain_name
  type    = "MX"
  ttl     = 300
  records = var.mx_records
}

# Registros TXT para SPF
resource "aws_route53_record" "spf" {
  count   = var.create_spf_record ? 1 : 0
  zone_id = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
  name    = local.domain_name
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 ${join(" ", var.spf_records)} -all"]
}

# Registros DMARC
resource "aws_route53_record" "dmarc" {
  count   = var.create_dmarc_record ? 1 : 0
  zone_id = var.create_zone ? aws_route53_zone.main[0].id : var.hosted_zone_id
  name    = "_dmarc.${local.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=${var.dmarc_policy}; rua=${var.dmarc_report_email}"]
}

# Health Check para el dominio principal
resource "aws_route53_health_check" "main" {
  count             = var.create_health_check ? 1 : 0
  fqdn              = local.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = "3"
  request_interval  = "30"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-health-check-${var.environment}"
    }
  )
}

# CloudWatch Alarms para el Health Check
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = var.create_health_check ? 1 : 0
  alarm_name          = "${var.project_name}-domain-health-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Monitoreo de salud del dominio ${local.domain_name}"
  alarm_actions       = var.alarm_actions

  dimensions = {
    HealthCheckId = aws_route53_health_check.main[0].id
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "dns" {
  dashboard_name = "${var.project_name}-dns-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = var.create_health_check ? [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", aws_route53_health_check.main[0].id]
          ] : []
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Estado del Health Check"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = var.create_health_check ? [
            ["AWS/Route53", "HealthCheckPercentageHealthy", "HealthCheckId", aws_route53_health_check.main[0].id]
          ] : []
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Porcentaje de Salud"
          period  = 300
        }
      }
    ]
  })
} 