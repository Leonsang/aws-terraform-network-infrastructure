locals {
  s3_origin_id = "${var.project_name}-origin-${var.environment}"
  waf_name     = "${var.project_name}-waf-${var.environment}"
}

# WAF ACL
resource "aws_wafv2_web_acl" "main" {
  name        = local.waf_name
  description = "WAF para CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regla de límite de tasa
  rule {
    name     = "RateLimit"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitRule"
      sampled_requests_enabled  = true
    }
  }

  # Regla de bloqueo de IPs
  dynamic "rule" {
    for_each = length(var.blocked_ips) > 0 ? [1] : []
    content {
      name     = "BlockedIPs"
      priority = 2

      override_action {
        none {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocked[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = "BlockedIPsRule"
        sampled_requests_enabled  = true
      }
    }
  }

  # Regla de protección contra SQL Injection
  rule {
    name     = "SQLInjectionProtection"
    priority = 3

    override_action {
      none {}
    }

    statement {
      sql_injection_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "SQLInjectionRule"
      sampled_requests_enabled  = true
    }
  }

  # Regla de protección contra XSS
  rule {
    name     = "XSSProtection"
    priority = 4

    override_action {
      none {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "XSSRule"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "WAFMainMetrics"
    sampled_requests_enabled  = true
  }

  tags = var.tags
}

# IP Set para IPs bloqueadas
resource "aws_wafv2_ip_set" "blocked" {
  count              = length(var.blocked_ips) > 0 ? 1 : 0
  name               = "${local.waf_name}-blocked-ips"
  description        = "IPs bloqueadas"
  scope             = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ips

  tags = var.tags
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled    = true
  comment            = "Distribución para ${var.project_name}-${var.environment}"
  price_class        = var.cloudfront_price_class
  web_acl_id         = aws_wafv2_web_acl.main.arn

  origin {
    domain_name = var.origin_domain_name
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null ? true : false
    acm_certificate_arn           = var.acm_certificate_arn
    ssl_support_method            = var.acm_certificate_arn == null ? null : "sni-only"
    minimum_protocol_version      = var.acm_certificate_arn == null ? "TLSv1" : "TLSv1.2_2021"
  }

  tags = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.project_name}-waf-blocked-requests-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.blocked_requests_threshold
  alarm_description   = "Monitoreo de solicitudes bloqueadas por WAF"
  alarm_actions       = var.alarm_actions

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = "Global"
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "cdn_waf" {
  dashboard_name = "${var.project_name}-cdn-waf-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.main.name, "Region", "Global"],
            ["AWS/WAFV2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.main.name, "Region", "Global"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Solicitudes WAF"
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
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.main.id],
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", aws_cloudfront_distribution.main.id],
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", aws_cloudfront_distribution.main.id],
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", aws_cloudfront_distribution.main.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Métricas CloudFront"
          period  = 300
        }
      }
    ]
  })
} 