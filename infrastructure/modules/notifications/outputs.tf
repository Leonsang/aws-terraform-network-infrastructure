output "sns_topic_arn" {
  description = "ARN del topic SNS principal"
  value       = aws_sns_topic.main.arn
}

output "sns_topic_name" {
  description = "Nombre del topic SNS principal"
  value       = aws_sns_topic.main.name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "ARN de la cola SQS principal"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL de la cola de mensajes muertos (DLQ)"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN de la cola de mensajes muertos (DLQ)"
  value       = aws_sqs_queue.dlq.arn
}

output "webhook_function_arn" {
  description = "ARN de la función Lambda para webhooks"
  value       = var.enable_webhooks ? aws_lambda_function.webhook_handler[0].arn : null
}

output "webhook_function_name" {
  description = "Nombre de la función Lambda para webhooks"
  value       = var.enable_webhooks ? aws_lambda_function.webhook_handler[0].function_name : null
}

output "service_health_rule_arn" {
  description = "ARN de la regla EventBridge para salud del servicio"
  value       = aws_cloudwatch_event_rule.service_health.arn
}

output "dlq_alarm_arn" {
  description = "ARN de la alarma de mensajes en DLQ"
  value       = aws_cloudwatch_metric_alarm.dlq_messages.arn
}

output "failed_notifications_alarm_arn" {
  description = "ARN de la alarma de notificaciones fallidas"
  value       = aws_cloudwatch_metric_alarm.failed_notifications.arn
}

output "notifications_dashboard_name" {
  description = "Nombre del dashboard de notificaciones"
  value       = aws_cloudwatch_dashboard.notifications.dashboard_name
} 