# Módulo de monitoreo para el proyecto de Detección de Fraude Financiero
# Implementa los componentes de monitoreo: CloudWatch, SNS

# Tema SNS para alertas
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-alerts"
    Environment = var.environment
  }
}

# Suscripción por email al tema SNS
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Dashboard de CloudWatch
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"
  
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
            ["AWS/Glue", "ETL Jobs Running", "JobName", "${var.project_name}-${var.environment}-etl-job"],
            [".", "ETL Jobs Succeeded", ".", "."],
            [".", "ETL Jobs Failed", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Glue ETL Jobs"
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
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-data-quality"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Data Quality"
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
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-${var.environment}-realtime-fraud"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Realtime Fraud"
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
            ["AWS/Kinesis", "GetRecords.IteratorAgeMilliseconds", "StreamName", "${var.project_name}-${var.environment}-transactions"],
            [".", "ReadProvisionedThroughputExceeded", ".", "."],
            [".", "WriteProvisionedThroughputExceeded", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Kinesis Stream"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${var.project_name}-${var.environment}-card-stats"],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "DynamoDB Capacity"
          period  = 300
        }
      }
    ]
  })
}

# Alarma para errores en el job de Glue
resource "aws_cloudwatch_metric_alarm" "glue_job_failure" {
  alarm_name          = "${var.project_name}-${var.environment}-glue-job-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ETL Jobs Failed"
  namespace           = "AWS/Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Esta alarma se activa cuando un job de Glue falla"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    JobName = "${var.project_name}-${var.environment}-etl-job"
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-glue-job-failure"
    Environment = var.environment
  }
}

# Alarma para errores en la función Lambda de calidad de datos
resource "aws_cloudwatch_metric_alarm" "lambda_data_quality_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-data-quality-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Esta alarma se activa cuando hay errores en la función Lambda de calidad de datos"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    FunctionName = "${var.project_name}-${var.environment}-data-quality"
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-data-quality-errors"
    Environment = var.environment
  }
}

# Alarma para errores en la función Lambda de procesamiento en tiempo real
resource "aws_cloudwatch_metric_alarm" "lambda_realtime_fraud_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-realtime-fraud-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Esta alarma se activa cuando hay errores en la función Lambda de procesamiento en tiempo real"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    FunctionName = "${var.project_name}-${var.environment}-realtime-fraud"
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-realtime-fraud-errors"
    Environment = var.environment
  }
}

# Alarma para retraso en el procesamiento de Kinesis
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${var.project_name}-${var.environment}-kinesis-iterator-age"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 3600000 # 1 hora en milisegundos
  alarm_description   = "Esta alarma se activa cuando el retraso en el procesamiento de Kinesis es mayor a 1 hora"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    StreamName = "${var.project_name}-${var.environment}-transactions"
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-kinesis-iterator-age"
    Environment = var.environment
  }
} 