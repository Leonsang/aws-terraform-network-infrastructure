terraform {
  required_version = ">= 1.0.0"
}

locals {
  test_bucket_name = "${var.project_name}-tests-${var.environment}"
  lambda_name     = "${var.project_name}-test-runner-${var.environment}"
}

# Bucket S3 para resultados de pruebas
resource "aws_s3_bucket" "test_results" {
  bucket = "${var.project_name}-${var.environment}-test-results-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-test-results"
  })
}

resource "aws_s3_bucket_versioning" "test_results" {
  bucket = aws_s3_bucket.test_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_results" {
  bucket = aws_s3_bucket.test_results.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Lambda para ejecutar pruebas
resource "aws_lambda_function" "test_runner" {
  filename         = "${path.module}/lambda/test_runner.zip"
  function_name    = local.lambda_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "main.lambda_handler"
  runtime         = "python3.9"
  timeout         = 900
  memory_size     = 1024

  environment {
    variables = {
      TEST_BUCKET          = aws_s3_bucket.test_results.id
      PROJECT_NAME         = var.project_name
      ENVIRONMENT         = var.environment
      SAGEMAKER_ENDPOINT  = var.sagemaker_endpoint_name
      API_GATEWAY_URL     = var.api_gateway_url
      SNS_TOPIC_ARN       = var.notification_topic_arn
      TEST_DATA_LOCATION  = var.test_data_location
      THRESHOLD_ACCURACY  = var.threshold_accuracy
      THRESHOLD_PRECISION = var.threshold_precision
      THRESHOLD_RECALL    = var.threshold_recall
      THRESHOLD_F1        = var.threshold_f1
    }
  }

  tags = var.tags
}

# Rol IAM para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-test-lambda-role-${var.environment}"

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

  tags = var.tags
}

# Política para el rol de Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "terraform-aws-test-lambda-policy-dev"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::terraform-aws-dev-processed",
          "arn:aws:s3:::terraform-aws-dev-processed/test-data/*"
        ]
      }
    ]
  })
}

# EventBridge Rule para pruebas programadas
resource "aws_cloudwatch_event_rule" "scheduled_tests" {
  name                = "${var.project_name}-scheduled-tests-${var.environment}"
  description         = "Ejecuta pruebas de calidad periódicamente"
  schedule_expression = var.test_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "test_lambda" {
  rule      = aws_cloudwatch_event_rule.scheduled_tests.name
  target_id = "RunTests"
  arn       = aws_lambda_function.test_runner.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_runner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_tests.arn
}

# Dashboard de métricas de calidad
resource "aws_cloudwatch_dashboard" "quality_metrics" {
  dashboard_name = "${var.project_name}-quality-metrics-${var.environment}"

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
            ["${var.project_name}/ModelQuality", "Accuracy", "Environment", var.environment],
            [".", "Precision", ".", "."],
            [".", "Recall", ".", "."],
            [".", "F1Score", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas de Calidad del Modelo"
          period  = 3600
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
            ["${var.project_name}/APIQuality", "Latency", "Environment", var.environment],
            [".", "ErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas de Calidad de API"
          period  = 300
        }
      }
    ]
  })
}

# Alarmas de calidad
resource "aws_cloudwatch_metric_alarm" "model_accuracy" {
  alarm_name          = "${var.project_name}-model-accuracy-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Accuracy"
  namespace           = "${var.project_name}/ModelQuality"
  period             = "3600"
  statistic          = "Average"
  threshold          = var.threshold_accuracy
  alarm_description  = "La precisión del modelo ha caído por debajo del umbral"
  alarm_actions      = [var.notification_topic_arn]

  dimensions = {
    Environment = var.environment
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "${var.project_name}-api-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorRate"
  namespace           = "${var.project_name}/APIQuality"
  period             = "300"
  statistic          = "Average"
  threshold          = var.threshold_api_errors
  alarm_description  = "La tasa de errores de la API ha superado el umbral"
  alarm_actions      = [var.notification_topic_arn]

  dimensions = {
    Environment = var.environment
  }

  tags = var.tags
}

# CodeBuild para pruebas de infraestructura
resource "aws_codebuild_project" "infrastructure_tests" {
  name          = "${var.project_name}-${var.environment}-infra-tests"
  description   = "Proyecto de pruebas de infraestructura"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.test_compute_type
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
  }

  source {
    type            = "GITHUB"
    location        = var.repository_url
    git_clone_depth = 1
    buildspec       = "buildspec-test.yml"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets           = var.subnet_ids
    security_group_ids = [aws_security_group.codebuild.id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-infra-tests"
      stream_name = "infrastructure-tests"
      status      = "ENABLED"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.test_results.id}/infrastructure-tests"
    }
  }

  tags = var.tags
}

# Security Group para CodeBuild
resource "aws_security_group" "codebuild" {
  name        = "${var.project_name}-${var.environment}-codebuild-sg"
  description = "Security group para CodeBuild de pruebas"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-codebuild-sg"
  })
}

# EventBridge Rule para ejecución programada de pruebas
resource "aws_cloudwatch_event_rule" "test_schedule" {
  name                = "${var.project_name}-${var.environment}-test-schedule"
  description         = "Programa de ejecución de pruebas de infraestructura"
  schedule_expression = var.test_schedule
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "test_target" {
  rule      = aws_cloudwatch_event_rule.test_schedule.name
  target_id = "RunInfrastructureTests"
  arn       = aws_codebuild_project.infrastructure_tests.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# CloudWatch Dashboard para resultados de pruebas
resource "aws_cloudwatch_dashboard" "test_results" {
  dashboard_name = "${var.project_name}-${var.environment}-test-results"

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
            ["AWS/CodeBuild", "SucceededBuilds", "ProjectName", aws_codebuild_project.infrastructure_tests.name],
            [".", "FailedBuilds", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Resultados de Pruebas"
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
            ["AWS/CodeBuild", "Duration", "ProjectName", aws_codebuild_project.infrastructure_tests.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Duración de Pruebas"
          period  = 300
        }
      }
    ]
  })
}

# SNS Topic para notificaciones de pruebas
resource "aws_sns_topic" "test_notifications" {
  name = "${var.project_name}-${var.environment}-test-notifications"
  
  tags = var.tags
}

resource "aws_sns_topic_subscription" "test_email_target" {
  count     = length(var.test_notification_emails)
  topic_arn = aws_sns_topic.test_notifications.arn
  protocol  = "email"
  endpoint  = var.test_notification_emails[count.index]
}

# CloudWatch Alarm para fallos en pruebas
resource "aws_cloudwatch_metric_alarm" "test_failures" {
  alarm_name          = "${var.project_name}-${var.environment}-test-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedBuilds"
  namespace           = "AWS/CodeBuild"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Monitoreo de fallos en pruebas de infraestructura"
  alarm_actions      = [aws_sns_topic.test_notifications.arn]

  dimensions = {
    ProjectName = aws_codebuild_project.infrastructure_tests.name
  }

  tags = var.tags
}

# IAM Role para CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

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
  name = "${var.project_name}-${var.environment}-codebuild-policy"
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
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.test_results.arn,
          "${aws_s3_bucket.test_results.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role para EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-${var.environment}-eventbridge-role"

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
  name = "${var.project_name}-${var.environment}-eventbridge-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.infrastructure_tests.arn
      }
    ]
  })
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {} 