locals {
  waf_name = "${var.project_name}-waf-${var.environment}"
  log_bucket = "${var.project_name}-security-logs-${var.environment}"
  config_bucket_name = "${var.project_name}-config-${var.environment}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Obtener cuenta actual
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Bucket S3 para logs de seguridad
resource "aws_s3_bucket" "security_logs" {
  bucket = local.log_bucket
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# WAF para API Gateway
resource "aws_wafv2_web_acl" "api" {
  name        = "${var.project_name}-waf-${var.environment}"
  description = "WAF para proteger la API"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-sql-injection"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "SQLiRuleMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "WAFMetric"
    sampled_requests_enabled  = true
  }
}

# Conjunto de IPs maliciosas
resource "aws_wafv2_ip_set" "malicious" {
  name               = "${var.project_name}-malicious-ips-${var.environment}"
  description        = "IPs identificadas como maliciosas"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ips

  tags = var.tags
}

# Habilitar GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = var.tags
}

# AWS Organizations
resource "aws_organizations_organization" "main" {
  count = var.create_organization ? 1 : 0
  
  feature_set = "ALL"
  
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

# Service Control Policy
resource "aws_organizations_policy" "scp" {
  count = var.create_organization ? 1 : 0
  
  name = "${var.project_name}-scp-${var.environment}"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid = "DenyLeavingOrganization"
        Effect = "Deny"
        Action = "organizations:LeaveOrganization"
        Resource = "*"
      },
      {
        Sid = "RequireIMDSv2"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotEquals = {
            "ec2:MetadataHttpTokens" = "required"
          }
        }
      }
    ], var.additional_scp_statements)
  })
}

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config-recorder-${var.environment}"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config-delivery-${var.environment}"
  s3_bucket_name = aws_s3_bucket.config.id
  s3_key_prefix  = "config"
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# S3 Bucket para AWS Config
resource "aws_s3_bucket" "config" {
  bucket = "terraform-aws-config-dev-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  force_destroy = true

  tags = {
    Name        = "terraform-aws-config-dev"
    Environment = "dev"
    Project     = "terraform-aws"
    Terraform   = "true"
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Security Hub
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# IAM Password Policy
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = var.minimum_password_length
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters   = true
  require_symbols               = true
  allow_users_to_change_password = true
  max_password_age              = var.max_password_age
  password_reuse_prevention     = var.password_reuse_prevention
}

# Rol IAM para AWS Config
resource "aws_iam_role" "config" {
  name = "${var.project_name}-config-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "config_policy" {
  name = "${var.project_name}-config-policy-${var.environment}"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "config:Put*",
          "config:Get*",
          "config:List*",
          "config:Describe*",
          "config:Deliver*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.config.arn}",
          "${aws_s3_bucket.config.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch Alarmas
resource "aws_cloudwatch_metric_alarm" "security_hub_findings" {
  count               = var.enable_security_hub ? 1 : 0
  alarm_name          = "${var.project_name}-security-findings-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityHubFindingsCount"
  namespace           = "AWS/SecurityHub"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.security_findings_threshold
  alarm_description   = "Monitoreo de hallazgos de seguridad"
  alarm_actions       = var.alarm_actions

  dimensions = {
    Severity = "CRITICAL"
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-${var.environment}-security"

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
            ["AWS/WAF", "BlockedRequests", "WebACL", aws_wafv2_web_acl.api.name],
            ["AWS/WAF", "AllowedRequests", "WebACL", aws_wafv2_web_acl.api.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "WAF Requests"
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
            ["AWS/GuardDuty", "FindingsCount", "Severity", "High"],
            ["AWS/GuardDuty", "FindingsCount", "Severity", "Medium"],
            ["AWS/GuardDuty", "FindingsCount", "Severity", "Low"]
          ]
          view    = "timeSeries"
          stacked = true
          region  = data.aws_region.current.name
          title   = "GuardDuty Findings"
          period  = 3600
        }
      }
    ]
  })
}

# Notificaciones de seguridad
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts-${var.environment}"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "security_email" {
  count     = length(var.security_alert_emails)
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_alert_emails[count.index]
}

# EventBridge Rule para eventos de seguridad
resource "aws_cloudwatch_event_rule" "security_events" {
  name        = "${var.project_name}-security-events-${var.environment}"
  description = "Regla para eventos de seguridad"
  event_pattern = jsonencode({
    source = ["aws.securityhub", "aws.guardduty", "aws.config"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "security_notifications" {
  rule      = aws_cloudwatch_event_rule.security_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
  input_transformer {
    input_paths = {
      "source" = "$.source",
      "time"    = "$.time",
      "detail"  = "$.detail"
    }
    input_template = <<EOF
{
  "message": "Alerta de Seguridad",
  "source": <source>,
  "time": <time>,
  "detail": <detail>
}
EOF
  }
}

# Alarmas de seguridad
resource "aws_cloudwatch_metric_alarm" "high_blocked_requests" {
  alarm_name          = "${var.project_name}-high-blocked-requests-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAF"
  period             = "300"
  statistic          = "Sum"
  threshold          = var.waf_blocked_requests_threshold
  alarm_description  = "Número alto de requests bloqueados por WAF"
  alarm_actions      = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.api.name
    Region = var.aws_region
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_severity_findings" {
  alarm_name          = "${var.project_name}-high-severity-findings-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FindingsCount"
  namespace           = "AWS/GuardDuty"
  period             = "3600"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Se han detectado hallazgos de alta severidad en GuardDuty"
  alarm_actions      = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    Detector = aws_guardduty_detector.main.id
    Severity = "High"
  }

  tags = var.tags
}

# KMS Key para encriptación
resource "aws_kms_key" "main" {
  description             = "KMS key para ${var.project_name}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

# Rol IAM para Glue
resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-${var.environment}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Política para el rol de Glue
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Rol IAM para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Política para el rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política para permitir que Lambda escriba en S3
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.project_name}-${var.environment}-lambda-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-raw/*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-raw"
        ]
      }
    ]
  })
}

# Rol IAM para Redshift
resource "aws_iam_role" "redshift" {
  name = "${var.project_name}-redshift-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "redshift_policy" {
  name = "${var.project_name}-redshift-policy-${var.environment}"
  role = aws_iam_role.redshift.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "redshift:*",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-${var.environment}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "step_functions_permissions" {
  name = "step-functions-permissions"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:ValidateStateMachineDefinition",
          "states:CreateStateMachine",
          "states:DeleteStateMachine",
          "states:UpdateStateMachine",
          "states:StartExecution",
          "states:StopExecution",
          "states:ListExecutions"
        ]
        Resource = "*"
      }
    ]
  })
} 