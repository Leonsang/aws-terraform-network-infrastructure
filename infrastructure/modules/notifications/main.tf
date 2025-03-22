locals {
  sns_name = "${var.project_name}-notifications-${var.environment}"
  dlq_name = "${var.project_name}-dlq-${var.environment}"
}

# SNS Topic Principal
resource "aws_sns_topic" "main" {
  name = local.sns_name
  tags = var.tags
}

# Suscripciones de Email
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.email_subscriptions)
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = var.email_subscriptions[count.index]
}

# Suscripciones de SMS
resource "aws_sns_topic_subscription" "sms" {
  count     = length(var.sms_subscriptions)
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sms"
  endpoint  = var.sms_subscriptions[count.index]
}

# Cola SQS para Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = local.dlq_name
  tags = var.tags
}

# Cola SQS Principal
resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-queue-${var.environment}"
  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = var.tags
}

# Política para permitir que SNS publique en SQS
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.main.arn
          }
        }
      }
    ]
  })
}

# Suscripción de SQS a SNS
resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn
}

# EventBridge Rules
resource "aws_cloudwatch_event_rule" "service_health" {
  name        = "${var.project_name}-service-health-${var.environment}"
  description = "Captura eventos de salud de servicios"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "service_health" {
  rule      = aws_cloudwatch_event_rule.service_health.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.main.arn

  input_transformer {
    input_paths = {
      service     = "$.detail.service"
      eventType   = "$.detail.eventTypeCode"
      startTime   = "$.detail.startTime"
      description = "$.detail.eventDescription[0].latestDescription"
    }
    input_template = "Alerta de Salud de Servicio AWS\nServicio: <service>\nTipo de Evento: <eventType>\nHora de Inicio: <startTime>\nDescripción: <description>"
locals {
  lambda_name = "${var.project_name}-notification-handler-${var.environment}"
  topic_name  = "${var.project_name}-alerts-${var.environment}"
}

# Tópico SNS principal
resource "aws_sns_topic" "fraud_alerts" {
  name = local.topic_name
  tags = var.tags
}

# Política de SNS
resource "aws_sns_topic_policy" "fraud_alerts" {
  arn = aws_sns_topic.fraud_alerts.arn

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
        Resource = aws_sns_topic.fraud_alerts.arn
      },
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.fraud_alerts.arn
      }
    ]
  })
}

# Lambda para procesar notificaciones
resource "aws_lambda_function" "notification_handler" {
  filename         = "${path.module}/lambda/notification_handler.zip"
  function_name    = local.lambda_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "main.lambda_handler"
  runtime         = "python3.8"
  timeout         = 30
  memory_size     = 128

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      EMAIL_TOPIC_ARN   = aws_sns_topic.fraud_alerts.arn
      ENVIRONMENT      = var.environment
    }
  }

  tags = var.tags
}

# Rol IAM para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-notification-lambda-role-${var.environment}"

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

# Política para Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-notification-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_sns_topic.fraud_alerts.arn,
          "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/${local.lambda_name}:*"
        ]
      }
    ]
  })
}

# Suscripción por email
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.email_subscribers)
  topic_arn = aws_sns_topic.fraud_alerts.arn
  protocol  = "email"
  endpoint  = var.email_subscribers[count.index]
}

# CloudWatch Log Group para Lambda
resource "aws_cloudwatch_log_group" "notification_lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 30
  tags             = var.tags
}

# Filtros de métricas para diferentes tipos de alertas
resource "aws_cloudwatch_log_metric_filter" "high_risk_alerts" {
  name           = "${var.project_name}-high-risk-alerts-${var.environment}"
  pattern        = "[timestamp, requestId, level=ALERT, message=*High Risk*]"
  log_group_name = aws_cloudwatch_log_group.notification_lambda.name

  metric_transformation {
    name          = "HighRiskAlerts"
    namespace     = "${var.project_name}/Notifications"
    value         = "1"
    default_value = "0"
  }
}

# Alarma para alta frecuencia de alertas
resource "aws_cloudwatch_metric_alarm" "high_alert_frequency" {
  alarm_name          = "${var.project_name}-high-alert-frequency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name        = "HighRiskAlerts"
  namespace          = "${var.project_name}/Notifications"
  period             = "300"
  statistic          = "Sum"
  threshold          = var.high_risk_threshold
  alarm_description  = "Alta frecuencia de alertas de alto riesgo detectada"
  alarm_actions      = [aws_sns_topic.fraud_alerts.arn]

  tags = var.tags
}

# Dashboard para monitoreo de notificaciones
resource "aws_cloudwatch_dashboard" "notifications" {
  dashboard_name = "${var.project_name}-notifications-${var.environment}"

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
            ["${var.project_name}/Notifications", "HighRiskAlerts", "Environment", var.environment]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Alertas de Alto Riesgo"
          period  = 300
        }
      }
    ]
  })
} 