terraform {
  required_version = ">= 1.0.0"
}

locals {
  budget_name = "${var.project_name}-budget-${var.environment}"
}

data "aws_caller_identity" "current" {}

# Presupuesto mensual
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-monthly-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 80
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
    subscriber_email_addresses = var.cost_alert_emails
  }
}

# Presupuestos por servicio
resource "aws_budgets_budget" "service_budgets" {
  for_each = var.service_budget_amounts

  name              = "${var.project_name}-${each.key}-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = each.value
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 80
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
    subscriber_email_addresses = var.cost_alert_emails
  }
}

# Cost and Usage Report
resource "aws_cur_report_definition" "main" {
  report_name                = "${var.project_name}-${var.environment}-cost-report"
  time_unit                 = "HOURLY"
  format                    = "Parquet"
  compression               = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                 = var.cost_report_bucket_name
  s3_region                 = var.region
  s3_prefix                 = "${var.project_name}/${var.environment}/cost-reports"
  report_versioning        = "OVERWRITE_REPORT"
  refresh_closed_reports   = true
}

# Monitor de anomalías por servicio
resource "aws_ce_anomaly_monitor" "main" {
  name              = "${var.project_name}-cost-monitor-${var.environment}"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

# Monitor de anomalías para costos generales
resource "aws_ce_anomaly_monitor" "general" {
  count = var.enable_savings_plans ? 1 : 0
  name  = "${var.project_name}-general-monitor-${var.environment}"
  monitor_type = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

# CloudWatch Dashboard para costos
resource "aws_cloudwatch_dashboard" "costs" {
  dashboard_name = "${var.project_name}-${var.environment}-costs"

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
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            for service in keys(var.service_budget_amounts) :
            ["AWS/Billing", "EstimatedCharges", "ServiceName", service, "Currency", "USD"]
          ]
          view    = "timeSeries"
          stacked = true
          region  = "us-east-1"
          title   = "Costos por Servicio"
          period  = 86400
        }
      }
    ]
  })
}

# SNS Topic para alertas de costos
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts-${var.environment}"
}

# Suscripción a anomalías
resource "aws_ce_anomaly_subscription" "main" {
  name      = "${var.project_name}-anomaly-subscription-${var.environment}"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.main.arn]

  subscriber {
    type    = "EMAIL"
    address = var.cost_alert_emails[0]
  }
}

# Suscripción a anomalías de costos generales
resource "aws_ce_anomaly_subscription" "general" {
  count = var.enable_savings_plans ? 1 : 0
  name      = "${var.project_name}-general-subscription-${var.environment}"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.general[0].arn]

  subscriber {
    type    = "EMAIL"
    address = var.cost_alert_emails[0]
  }
}

# Categoría de costos por ambiente
resource "aws_ce_cost_category" "environment" {
  name = "${var.project_name}-${var.environment}-environment"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "Development"
    rule {
      dimension {
        key   = "LINKED_ACCOUNT"
        values = [data.aws_caller_identity.current.account_id]
      }
    }
  }

  tags = var.tags
}

# Suscripción por email a alertas de costos
resource "aws_sns_topic_subscription" "cost_email" {
  count     = length(var.cost_alert_emails)
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.cost_alert_emails[count.index]
}

# Alarma de CloudWatch para presupuesto mensual
resource "aws_cloudwatch_metric_alarm" "monthly_budget" {
  alarm_name          = "${var.project_name}-monthly-budget-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic          = "Maximum"
  threshold          = var.monthly_budget_amount * (var.budget_alert_threshold / 100)
  alarm_description   = "Alerta cuando los gastos mensuales superan el umbral establecido"
  alarm_actions       = var.alarm_actions

  dimensions = {
    Currency = "USD"
  }
}

# Regla de CloudWatch Events para recomendaciones de costos
resource "aws_cloudwatch_event_rule" "cost_optimization" {
  name                = "${var.project_name}-cost-optimization-${var.environment}"
  description         = "Regla para recomendaciones de optimización de costos"
  schedule_expression = "rate(7 days)"
}

# Target de CloudWatch Events para enviar recomendaciones a SNS
resource "aws_cloudwatch_event_target" "cost_optimization" {
  rule      = aws_cloudwatch_event_rule.cost_optimization.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.cost_alerts.arn
} 