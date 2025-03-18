# Módulo de seguridad mejorado para el proyecto de Detección de Fraude Financiero

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  })
}

# KMS Key para encriptación de datos
resource "aws_kms_key" "data_encryption" {
  description             = "KMS key for data encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-data-encryption"
    Purpose = "Data Encryption"
  })
}

# Alias para la KMS Key
resource "aws_kms_alias" "data_encryption" {
  name          = "alias/${var.project_name}-${var.environment}-data-encryption"
  target_key_id = aws_kms_key.data_encryption.key_id
}

# Secrets Manager para credenciales
resource "aws_secretsmanager_secret" "redshift_credentials" {
  name = "${var.project_name}-${var.environment}-redshift-credentials"
  description = "Credentials for Redshift cluster"
  kms_key_id = aws_kms_key.data_encryption.arn

  tags = local.common_tags
}

# CloudTrail para auditoría
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  enable_log_file_validation   = true
  kms_key_id                   = aws_kms_key.data_encryption.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = local.common_tags
}

# IAM Policy para CloudTrail
resource "aws_iam_policy" "cloudtrail_policy" {
  name = "${var.project_name}-${var.environment}-cloudtrail-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          "${var.cloudtrail_bucket_arn}/*",
          var.cloudtrail_bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.cloudtrail_log_group_arn}:*"
      }
    ]
  })
}

# Rol IAM para CloudTrail
resource "aws_iam_role" "cloudtrail_role" {
  name = "${var.project_name}-${var.environment}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Adjuntar política a rol de CloudTrail
resource "aws_iam_role_policy_attachment" "cloudtrail_policy_attachment" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn = aws_iam_policy.cloudtrail_policy.arn
}

# Configuración de GuardDuty
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

  tags = local.common_tags
}

# Configuración de Security Hub
resource "aws_securityhub_account" "main" {
  control_finding_generator = "SECURITY_CONTROL"
  auto_enable_controls     = true
  enable_default_standards = true

  tags = local.common_tags
}

# Configuración de WAF
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-${var.environment}-web-acl"
  description = "WAF Web ACL for API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${var.project_name}-${var.environment}-web-acl-metric"
    sampled_requests_enabled  = true
  }

  tags = local.common_tags
}

# Reglas de WAF
resource "aws_wafv2_web_acl_rule" "rate_limit" {
  name        = "RateLimitRule"
  description = "Rate limiting rule"
  priority    = 1
  action {
    block {}
  }
  statement {
    rate_based_statement {
      limit              = 2000
      aggregate_key_type = "IP"
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "RateLimitRuleMetric"
    sampled_requests_enabled  = true
  }
}

# Configuración de AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }

  configuration_recorder_status {
    name     = aws_config_configuration_recorder.main.name
    recording = true
  }

  tags = local.common_tags
}

# Rol IAM para AWS Config
resource "aws_iam_role" "config_role" {
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

  tags = local.common_tags
}

# Política para AWS Config
resource "aws_iam_role_policy" "config_policy" {
  name = "${var.project_name}-${var.environment}-config-policy"
  role = aws_iam_role.config_role.id

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
      }
    ]
  })
}

# Configuración de Macie
resource "aws_macie2_account" "main" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                      = "ENABLED"

  tags = local.common_tags
}

# Configuración de Inspector
resource "aws_inspector_assessment_target" "main" {
  name = "${var.project_name}-${var.environment}-assessment-target"

  tags = local.common_tags
}

# Configuración de Shield
resource "aws_shield_protection" "main" {
  name         = "${var.project_name}-${var.environment}-shield"
  resource_arn = var.api_gateway_arn

  tags = local.common_tags
}

# Configuración de Shield Advanced
resource "aws_shield_protection_group" "main" {
  protection_group_id = "${var.project_name}-${var.environment}-shield-group"
  aggregation         = "MAX"
  pattern            = "ALL"

  tags = local.common_tags
}

# Rol IAM para AWS Glue
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
resource "aws_iam_policy" "glue_policy" {
  name        = "${var.project_name}-${var.environment}-glue-policy"
  description = "Política para el servicio AWS Glue"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.raw_bucket_arn,
          "${var.raw_bucket_arn}/*",
          var.proc_bucket_arn,
          "${var.proc_bucket_arn}/*",
          var.analy_bucket_arn,
          "${var.analy_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "glue:*Database*",
          "glue:*Table*",
          "glue:*Partition*",
          "glue:*UserDefinedFunction*",
          "glue:*Crawler*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Adjuntar la política al rol de Glue
resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

# Adjuntar la política administrada de Glue
resource "aws_iam_role_policy_attachment" "glue_service_attachment" {
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
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-${var.environment}-lambda-policy"
  description = "Política para las funciones Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.raw_bucket_arn,
          "${var.raw_bucket_arn}/*",
          var.proc_bucket_arn,
          "${var.proc_bucket_arn}/*",
          var.analy_bucket_arn,
          "${var.analy_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:*:*:table/${var.project_name}-${var.environment}-*"
      },
      {
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:kinesis:*:*:stream/${var.project_name}-${var.environment}-*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Adjuntar la política al rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Adjuntar la política básica de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Rol IAM para CloudWatch Events
resource "aws_iam_role" "events_role" {
  name = "${var.project_name}-${var.environment}-events-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Política para el rol de CloudWatch Events
resource "aws_iam_policy" "events_policy" {
  name        = "${var.project_name}-${var.environment}-events-policy"
  description = "Política para CloudWatch Events"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "glue:StartJobRun"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:glue:*:*:job/${var.project_name}-${var.environment}-*"
      }
    ]
  })
}

# Adjuntar la política al rol de CloudWatch Events
resource "aws_iam_role_policy_attachment" "events_policy_attachment" {
  role       = aws_iam_role.events_role.name
  policy_arn = aws_iam_policy.events_policy.arn
}

# Rol IAM para Redshift
resource "aws_iam_role" "redshift_role" {
  name = "${var.project_name}-${var.environment}-redshift-role"
  
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
  
  tags = local.common_tags
}

# Grupo de seguridad para Redshift
resource "aws_security_group" "redshift" {
  name_prefix = "${var.project_name}-${var.environment}-redshift-"
  description = "Grupo de seguridad para el cluster de Redshift"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Política para el rol de Redshift
resource "aws_iam_policy" "redshift_policy" {
  name        = "${var.project_name}-${var.environment}-redshift-policy"
  description = "Política para el cluster de Redshift"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.proc_bucket_arn,
          "${var.proc_bucket_arn}/*",
          var.analy_bucket_arn,
          "${var.analy_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Adjuntar la política al rol de Redshift
resource "aws_iam_role_policy_attachment" "redshift_policy_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_policy.arn
}

# Adjuntar la política administrada de Redshift
resource "aws_iam_role_policy_attachment" "redshift_service_attachment" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSRedshiftServiceRole"
}

# Rol IAM para QuickSight
resource "aws_iam_role" "quicksight_role" {
  name = "${var.project_name}-${var.environment}-quicksight-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Política para el rol de QuickSight
resource "aws_iam_policy" "quicksight_policy" {
  name        = "${var.project_name}-${var.environment}-quicksight-policy"
  description = "Política para QuickSight"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.analy_bucket_arn,
          "${var.analy_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "athena:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetDatabase",
          "glue:GetDatabases"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters",
          "redshift:DescribeClusterSubnetGroups",
          "redshift:DescribeClusterSecurityGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Adjuntar la política al rol de QuickSight
resource "aws_iam_role_policy_attachment" "quicksight_policy_attachment" {
  role       = aws_iam_role.quicksight_role.name
  policy_arn = aws_iam_policy.quicksight_policy.arn
} 
} 