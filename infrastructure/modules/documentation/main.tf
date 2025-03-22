terraform {
  required_version = ">= 1.0.0"
}

locals {
  docs_bucket_name = "${var.project_name}-docs-${var.environment}"
  lambda_function_name = "${var.project_name}-docs-generator-${var.environment}"
}

# Bucket S3 para la documentación
resource "aws_s3_bucket" "documentation" {
  bucket = "${var.project_name}-${var.environment}-docs-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-docs"
  })
}

resource "aws_s3_bucket_versioning" "documentation" {
  bucket = aws_s3_bucket.documentation.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documentation" {
  bucket = aws_s3_bucket.documentation.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "documentation" {
  bucket = aws_s3_bucket.documentation.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# CodeBuild para generación de documentación
resource "aws_codebuild_project" "documentation" {
  name          = "${var.project_name}-${var.environment}-docs"
  description   = "Proyecto de generación de documentación"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.docs_compute_type
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }

    environment_variable {
      name  = "DOCS_BUCKET"
      value = aws_s3_bucket.documentation.id
    }
  }

  source {
    type            = "GITHUB"
    location        = var.repository_url
    git_clone_depth = 1
    buildspec       = "buildspec-docs.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-docs"
      stream_name = "documentation"
      status      = "ENABLED"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.documentation.id}/build-logs"
    }
  }

  tags = var.tags
}

# EventBridge Rule para actualización automática de documentación
resource "aws_cloudwatch_event_rule" "docs_update" {
  name                = "${var.project_name}-${var.environment}-docs-update"
  description         = "Actualización automática de documentación"
  schedule_expression = var.docs_update_schedule
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "docs_target" {
  rule      = aws_cloudwatch_event_rule.docs_update.name
  target_id = "UpdateDocumentation"
  arn       = aws_codebuild_project.documentation.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# CloudWatch Dashboard para monitoreo de documentación
resource "aws_cloudwatch_dashboard" "documentation" {
  dashboard_name = "${var.project_name}-${var.environment}-docs"

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
            ["AWS/S3", "NumberOfObjects", "BucketName", aws_s3_bucket.documentation.id],
            [".", "BucketSizeBytes", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Métricas de Documentación"
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
            ["AWS/CodeBuild", "SucceededBuilds", "ProjectName", aws_codebuild_project.documentation.name],
            [".", "FailedBuilds", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Generación de Documentación"
          period  = 300
        }
      }
    ]
  })
}

# SNS Topic para notificaciones de documentación
resource "aws_sns_topic" "docs_notifications" {
  name = "${var.project_name}-${var.environment}-docs-notifications"
  
  tags = var.tags
}

resource "aws_sns_topic_subscription" "docs_email_target" {
  count     = length(var.docs_notification_emails)
  topic_arn = aws_sns_topic.docs_notifications.arn
  protocol  = "email"
  endpoint  = var.docs_notification_emails[count.index]
}

# CloudWatch Alarm para fallos en generación de documentación
resource "aws_cloudwatch_metric_alarm" "docs_failures" {
  alarm_name          = "${var.project_name}-${var.environment}-docs-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Monitoreo de fallos en generación de documentación"
  alarm_actions      = [aws_sns_topic.docs_notifications.arn]

  dimensions = {
    ProjectName = aws_codebuild_project.documentation.name
  }

  tags = var.tags
}

# IAM Role para CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-docs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-${var.environment}-docs-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy"
        ]
        Resource = [
          aws_s3_bucket.documentation.arn,
          "${aws_s3_bucket.documentation.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role para EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-${var.environment}-docs-eventbridge-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "${var.project_name}-${var.environment}-docs-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.documentation.arn
      }
    ]
  })
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {} 