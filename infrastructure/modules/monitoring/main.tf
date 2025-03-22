locals {
  monitoring_schedule_name = "${var.project_name}-model-monitor-${var.environment}"
  baseline_job_name       = "${var.project_name}-baseline-${var.environment}"
  monitoring_job_prefix   = "${var.project_name}-monitoring-${var.environment}"
  log_group_name = "/aws/${var.project_name}/${var.environment}"
  dashboard_name = "${var.project_name}-monitoring-${var.environment}"
}

# Rol IAM para Model Monitor
resource "aws_iam_role" "model_monitor_role" {
  name = "${var.project_name}-model-monitor-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para acceso a S3
resource "aws_iam_role_policy" "model_monitor_s3_policy" {
  name = "${var.project_name}-model-monitor-s3-policy-${var.environment}"
  role = aws_iam_role.model_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.monitoring_bucket_name}/*",
          "arn:aws:s3:::${var.monitoring_bucket_name}"
        ]
      }
    ]
  })
}

# Política para CloudWatch
resource "aws_iam_role_policy" "model_monitor_cloudwatch_policy" {
  name = "${var.project_name}-model-monitor-cloudwatch-policy-${var.environment}"
  role = aws_iam_role.model_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "xray:CreateSamplingRule",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:PutSamplingRules",
          "xray:PutTelemetryRecords",
          "xray:PutTraceSegments",
          "xray:PutUnsampledTraceSegments",
          "firehose:CreateDeliveryStream",
          "firehose:DeleteDeliveryStream",
          "firehose:DescribeDeliveryStream",
          "firehose:ListDeliveryStreams",
          "firehose:PutRecord",
          "firehose:PutRecordBatch",
          "firehose:UpdateDeliveryStream",
          "firehose:TagDeliveryStream",
          "firehose:UntagDeliveryStream"
        ]
        Resource = "*"
      }
    ]
  })
}

# Programación de monitoreo
resource "aws_sagemaker_monitoring_schedule" "model_monitor" {
  count = var.endpoint_name != "" ? 1 : 0
  name = local.monitoring_schedule_name

  monitoring_schedule_config {
    monitoring_type = "DataQuality"
    monitoring_job_definition_name = "${var.project_name}-job-${var.environment}"
    schedule_config {
      schedule_expression = var.monitoring_schedule
    }
  }
}

# Dashboard de CloudWatch
resource "aws_cloudwatch_dashboard" "model_monitoring" {
  dashboard_name = "${var.project_name}-model-monitoring-${var.environment}"
  
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
            ["AWS/CloudWatch", "MetricStreamOutputRecords", "Service", "CloudWatch", "MetricStreamName", "${var.project_name}-${var.environment}-metrics"],
            ["AWS/CloudWatch", "MetricStreamOutputRecords", "Service", "CloudWatch", "MetricStreamName", "${var.project_name}-${var.environment}-metrics", { "stat": "Sum", "period": "300" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas de Modelo"
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
            ["AWS/CloudWatch", "MetricStreamOutputRecords", "Service", "CloudWatch", "MetricStreamName", "${var.project_name}-${var.environment}-metrics"],
            ["AWS/CloudWatch", "MetricStreamOutputRecords", "Service", "CloudWatch", "MetricStreamName", "${var.project_name}-${var.environment}-metrics", { "stat": "Sum", "period": "300" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas de Procesamiento"
        }
      }
    ]
  })
}

# Alarma de Data Drift
resource "aws_cloudwatch_metric_alarm" "data_drift_alarm" {
  count = var.endpoint_name != "" ? 1 : 0
  alarm_name          = "${var.project_name}-data-drift-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DataDrift"
  namespace           = "AWS/SageMaker/Endpoints"
  period             = 300
  statistic          = "Average"
  threshold          = var.drift_threshold
  alarm_description  = "Alerta cuando se detecta data drift en el modelo"
  alarm_actions      = var.alarm_actions

  dimensions = {
    EndpointName = var.endpoint_name
  }

  tags = var.tags
}

# Grupo de logs para monitoreo
resource "aws_cloudwatch_log_group" "monitoring_logs" {
  name              = "/aws/sagemaker/ModelMonitoring/${local.monitoring_schedule_name}"
  retention_in_days = 30
  tags             = var.tags
}

# Log Group centralizado
resource "aws_cloudwatch_log_group" "main" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Regla de muestreo X-Ray - Temporalmente comentada hasta tener los permisos necesarios
/*
resource "aws_xray_sampling_rule" "main" {
  rule_name = "${var.project_name}-sampling-${var.environment}"
  priority  = 1000
  version   = 1
  reservoir_size = 1
  fixed_rate = 0.05
  host = "*"
  http_method = "*"
  url_path = "/*"
  service_name = "*"
  service_type = "*"
  resource_arn = "*"
}
*/

# CloudWatch Metric Streams para exportación en tiempo real
/*
resource "aws_cloudwatch_metric_stream" "main" {
  name          = "${var.project_name}-metric-stream-${var.environment}"
  role_arn      = aws_iam_role.metric_stream.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.metrics.arn
  output_format = "json"

  include_filter {
    namespace = "AWS/Lambda"
  }

  include_filter {
    namespace = "AWS/ApiGateway"
  }

  include_filter {
    namespace = "AWS/RDS"
  }

  include_filter {
    namespace = "AWS/ECS"
  }

  tags = var.tags
}
*/

# S3 Bucket para métricas
resource "aws_s3_bucket" "metrics" {
  count  = var.create_metrics_bucket ? 1 : 0
  bucket = "${var.project_name}-metrics-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "metrics" {
  count  = var.create_metrics_bucket ? 1 : 0
  bucket = aws_s3_bucket.metrics[0].id

  rule {
    id     = "metrics_lifecycle"
    status = "Enabled"

    filter {
      prefix = "metrics/"
    }

    transition {
      days          = var.metrics_transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.metrics_retention_days
    }
  }
}

# Roles IAM
resource "aws_iam_role" "metric_stream" {
  name = "${var.project_name}-metric-stream-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "streams.metrics.cloudwatch.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy para Metric Stream
/*
resource "aws_iam_role_policy" "metric_stream" {
  name = "${var.project_name}-metric-stream-${var.environment}"
  role = aws_iam_role.metric_stream.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [aws_kinesis_firehose_delivery_stream.metrics.arn]
      }
    ]
  })
}
*/

resource "aws_iam_role" "firehose" {
  name = "${var.project_name}-firehose-${var.environment}"

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

  tags = var.tags
}

# IAM Role Policy para Firehose
resource "aws_iam_role_policy" "firehose" {
  name = "${var.project_name}-firehose-${var.environment}"
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
          "s3:PutObject",
          "firehose:TagDeliveryStream"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-metrics-${var.environment}-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::${var.project_name}-metrics-${var.environment}-${data.aws_caller_identity.current.account_id}/*",
          "arn:aws:firehose:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deliverystream/${var.project_name}-metrics-${var.environment}"
        ]
      }
    ]
  })
}

# CloudWatch Dashboard Principal
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = local.dashboard_name

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
            ["AWS/Lambda", "Invocations", "FunctionName", "*"],
            [".", "Errors", ".", "*"],
            [".", "Duration", ".", "*"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda - General"
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
            ["AWS/ApiGateway", "Count", "ApiName", "*"],
            [".", "4XXError", ".", "*"],
            [".", "5XXError", ".", "*"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway - General"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "*"],
            [".", "FreeStorageSpace", ".", "*"],
            [".", "DatabaseConnections", ".", "*"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS - General"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "*"],
            [".", "MemoryUtilization", ".", "*"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS - General"
          period  = 300
        }
      }
    ]
  })
}

# Alarmas Generales
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Monitoreo de errores en funciones Lambda"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = "*"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project_name}-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = var.api_latency_threshold
  alarm_description   = "Monitoreo de latencia en API Gateway"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ApiName = "*"
  }

  tags = var.tags
}

# Obtener cuenta actual
data "aws_caller_identity" "current" {}

# SNS Topic para alertas
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-monitoring-alerts-${var.environment}"
  tags = var.tags
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
} 