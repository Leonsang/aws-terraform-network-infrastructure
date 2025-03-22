terraform {
  required_version = ">= 1.0.0"
}

locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
  config_bucket = "${var.project_name}-config-${var.environment}"
  audit_bucket  = "${var.project_name}-audit-${var.environment}"
}

# Bucket S3 para AWS Config
resource "aws_s3_bucket" "config" {
  bucket = "${var.project_name}-${var.environment}-config-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-config"
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
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bucket S3 para Audit Manager
resource "aws_s3_bucket" "audit" {
  bucket = local.audit_bucket
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Rol IAM para AWS Config
resource "aws_iam_role" "config" {
  name = "${var.project_name}-${var.environment}-config-role"

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

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Configuración de AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config-recorder-${var.environment}"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_configuration_recorder.main]
}

# Reglas de AWS Config
resource "aws_config_config_rule" "s3_bucket_encryption" {
  name = "${var.project_name}-${var.environment}-s3-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_versioning" {
  name = "${var.project_name}-${var.environment}-s3-versioning"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encryption" {
  name = "${var.project_name}-${var.environment}-rds-encryption"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Security Hub
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 0 : 1
}

resource "aws_securityhub_standards_subscription" "cis" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
}

resource "aws_securityhub_standards_subscription" "pci" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 0 : 1
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

  tags = local.common_tags
}

# Audit Manager
resource "aws_auditmanager_assessment" "main" {
  count = var.enable_audit_manager ? 0 : 1
  name = "terraform-aws-${var.environment}-assessment"
  description = "Monitoreo de cumplimiento"
  framework_id = "1b3871e3-3b5a-4b3e-8b3a-1b3871e3b5a4" # AWS Foundational Security Best Practices
  assessment_reports_destination {
    destination = "s3://terraform-aws-${var.environment}-audit-reports"
    destination_type = "S3"
  }
  roles {
    role_arn = aws_iam_role.audit_role.arn
  }
  scope {
    aws_accounts {
      id = data.aws_caller_identity.current.account_id
    }
    aws_services {
      service_name = "S3"
    }
  }
}

# IAM Role para Audit Manager
resource "aws_iam_role" "audit_role" {
  name = "${var.project_name}-${var.environment}-audit-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "auditmanager.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "audit" {
  role       = aws_iam_role.audit_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAuditManagerAdministratorAccess"
}

# EventBridge Rules para monitoreo de conformidad
resource "aws_cloudwatch_event_rule" "compliance_changes" {
  name        = "${var.project_name}-${var.environment}-compliance-changes"
  description = "Captura cambios en la conformidad"

  event_pattern = jsonencode({
    source = ["aws.config", "aws.securityhub", "aws.guardduty", "aws.auditmanager"]
    detail-type = [
      "Config Rules Compliance Change",
      "Security Hub Findings - Imported",
      "GuardDuty Finding",
      "Audit Manager Assessment Status Change"
    ]
  })

  tags = var.tags
}

resource "aws_sns_topic" "compliance_notifications" {
  name = "terraform-aws-dev-compliance-notifications"
  tags = {
    Environment = "dev"
    Project     = "terraform-aws"
    Terraform   = "true"
  }
}

resource "aws_sns_topic_subscription" "compliance_email" {
  topic_arn = aws_sns_topic.compliance_notifications.arn
  protocol  = "email"
  endpoint  = "ericksang@gmail.com"
}

resource "aws_cloudwatch_event_target" "notify_compliance" {
  rule      = aws_cloudwatch_event_rule.compliance_changes.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.compliance_notifications.arn

  input_transformer {
    input_paths = {
      source = "$.source"
      time   = "$.time"
      detail = "$.detail"
    }
    input_template = jsonencode({
      source    = "<source>"
      time      = "<time>"
      detail    = "<detail>"
      message   = "Compliance change detected"
    })
  }
}

# CloudWatch Dashboard para conformidad
resource "aws_cloudwatch_dashboard" "compliance" {
  dashboard_name = "${var.project_name}-${var.environment}-compliance"

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
            ["AWS/Config", "ConfigRulesEvaluationsFailed", "RuleName", "*"],
            [".", "ConfigRulesEvaluationsPassed", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Evaluaciones de Reglas de Config"
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
            ["AWS/SecurityHub", "SecurityHubFindingsCount", "Severity", "CRITICAL"],
            [".", ".", ".", "HIGH"],
            [".", ".", ".", "MEDIUM"]
          ]
          view    = "timeSeries"
          stacked = true
          region  = var.region
          title   = "Hallazgos de Security Hub"
          period  = 300
        }
      }
    ]
  })
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {} 