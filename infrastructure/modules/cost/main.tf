locals {
  budget_name = "${var.project_name}-budget-${var.environment}"
  alert_topic_name = "${var.project_name}-cost-alerts-${var.environment}"
}

# Tema SNS para alertas de costos
resource "aws_sns_topic" "cost_alerts" {
  name = local.alert_topic_name
  tags = var.tags
}

# Suscripción por email al tema SNS
resource "aws_sns_topic_subscription" "cost_alerts_email" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# Presupuesto mensual
resource "aws_budgets_budget" "monthly" {
  name              = "${local.budget_name}-monthly"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  
  limit_amount = var.monthly_budget_amount
  limit_unit   = "USD"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "project:${var.project_name}",
      "environment:${var.environment}"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 110
    threshold_type           = "PERCENTAGE"
    notification_type        = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }
}

# Presupuesto para SageMaker
resource "aws_budgets_budget" "sagemaker" {
  name              = "${local.budget_name}-sagemaker"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  
  limit_amount = var.sagemaker_budget_amount
  limit_unit   = "USD"

  cost_filter {
    name = "Service"
    values = ["Amazon SageMaker"]
  }

  cost_filter {
    name = "TagKeyValue"
    values = [
      "project:${var.project_name}",
      "environment:${var.environment}"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type           = "PERCENTAGE"
    notification_type        = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }
}

# Política de ahorro para instancias EC2
resource "aws_iam_role" "cost_optimizer" {
  name = "${var.project_name}-cost-optimizer-${var.environment}"

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

resource "aws_iam_role_policy" "cost_optimizer" {
  name = "${var.project_name}-cost-optimizer-policy-${var.environment}"
  role = aws_iam_role.cost_optimizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetSavingsPlansPurchaseRecommendation",
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Dashboard para costos
resource "aws_cloudwatch_dashboard" "cost_dashboard" {
  dashboard_name = "${var.project_name}-costs-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Costos Estimados Totales"
          period  = 86400
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/SageMaker", "CPUUtilization", "EndpointName", "*"],
            [".", "MemoryUtilization", ".", "*"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Utilización de Recursos SageMaker"
        }
      }
    ]
  })
}

# Métricas personalizadas en CloudWatch
resource "aws_cloudwatch_metric_alarm" "daily_cost_spike" {
  alarm_name          = "${var.project_name}-daily-cost-spike-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period             = "86400"
  statistic          = "Maximum"
  threshold          = var.daily_cost_threshold
  alarm_description  = "Esta alarma se activará cuando los costos diarios excedan el umbral establecido"
  alarm_actions      = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = var.tags
} 