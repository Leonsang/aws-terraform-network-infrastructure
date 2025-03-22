terraform {
  required_version = ">= 1.0.0"
}

locals {
  log_bucket_name = "${var.project_name}-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"
  common_tags     = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

# Obtener la cuenta actual
data "aws_caller_identity" "current" {}

# Bucket S3 para logs
resource "aws_s3_bucket" "logs" {
  bucket = local.log_bucket_name
  force_destroy = var.force_destroy_bucket

  tags = merge(
    var.tags,
    {
      Name = local.log_bucket_name
    }
  )
}

# Configuración del bucket
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

# Política de bucket
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      }
    ]
  })
}

# CloudWatch Log Group centralizado
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/${var.project_name}/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

# Kinesis Firehose para exportación de logs
resource "aws_kinesis_firehose_delivery_stream" "logs_to_s3" {
  name        = "${var.project_name}-${var.environment}-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.logs_bucket_arn
    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
    buffering_size     = 64
    buffering_interval = 60

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = local.common_tags
}

# Log Group para Firehose
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/firehose/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Log Group para aplicaciones
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/${var.environment}/app"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Log Group para sistema
resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/${var.project_name}/${var.environment}/system"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Log Group para auditoría
resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/${var.project_name}/${var.environment}/audit"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Log Stream para Firehose
resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# Rol IAM para Firehose
resource "aws_iam_role" "firehose" {
  name = "${var.project_name}-${var.environment}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

# Política para el rol de Firehose
resource "aws_iam_role_policy" "firehose" {
  name = "${var.project_name}-${var.environment}-firehose-policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          var.logs_bucket_arn,
          "${var.logs_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.firehose.arn}:*",
          "${aws_cloudwatch_log_group.firehose.arn}:log-stream:*"
        ]
      }
    ]
  })
}

# Subscription Filter para enviar logs a Firehose
resource "aws_cloudwatch_log_subscription_filter" "logs_to_firehose" {
  name            = "${var.project_name}-${var.environment}-logs-filter"
  log_group_name  = aws_cloudwatch_log_group.main.name
  filter_pattern  = var.filter_pattern
  destination_arn = aws_kinesis_firehose_delivery_stream.logs_to_s3.arn
  role_arn       = aws_iam_role.cloudwatch_to_firehose.arn
}

# Rol IAM para CloudWatch a Firehose
resource "aws_iam_role" "cloudwatch_to_firehose" {
  name = "${var.project_name}-${var.environment}-cloudwatch-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
      }
    ]
  })
}

# Política para el rol de CloudWatch a Firehose
resource "aws_iam_role_policy" "cloudwatch_to_firehose" {
  name = "${var.project_name}-${var.environment}-cloudwatch-firehose-policy"
  role = aws_iam_role.cloudwatch_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [aws_kinesis_firehose_delivery_stream.logs_to_s3.arn]
      }
    ]
  })
}

# Métricas personalizadas para monitoreo de logs
resource "aws_cloudwatch_metric_alarm" "log_delivery_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-log-delivery-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DeliveryToS3.Error"
  namespace           = "AWS/Firehose"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Monitorea errores en la entrega de logs a S3"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.logs_to_s3.name
  }

  tags = var.tags
}

# Dashboard para monitoreo de logs
resource "aws_cloudwatch_dashboard" "logs" {
  dashboard_name = "${var.project_name}-${var.environment}-logs"

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
            ["AWS/Firehose", "IncomingBytes", "DeliveryStreamName", aws_kinesis_firehose_delivery_stream.logs_to_s3.name],
            [".", "IncomingRecords", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Logs Entrantes"
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
            ["AWS/Firehose", "DeliveryToS3.Bytes", "DeliveryStreamName", aws_kinesis_firehose_delivery_stream.logs_to_s3.name],
            [".", "DeliveryToS3.Records", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Entrega a S3"
          period  = 300
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "error_logs" {
  alarm_name          = "${var.project_name}-${var.environment}-error-logs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "AWS/Logs"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description   = "This metric monitors error logs"
  alarm_actions      = [aws_sns_topic.log_alerts.arn]

  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.app.name
  }

  tags = local.common_tags
}

resource "aws_sns_topic" "log_alerts" {
  name = "${var.project_name}-${var.environment}-log-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "log_alerts_email" {
  topic_arn = aws_sns_topic.log_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
} 