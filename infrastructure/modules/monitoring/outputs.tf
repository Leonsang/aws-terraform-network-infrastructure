output "log_group_name" {
  description = "Nombre del grupo de logs centralizado"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_arn" {
  description = "ARN del grupo de logs centralizado"
  value       = aws_cloudwatch_log_group.main.arn
}

/*
output "xray_sampling_rule_name" {
  description = "Nombre de la regla de muestreo de X-Ray"
  value       = aws_xray_sampling_rule.main.rule_name
}

output "xray_sampling_rule_arn" {
  description = "ARN de la regla de muestreo de X-Ray"
  value       = aws_xray_sampling_rule.main.arn
}
*/

/*
output "metric_stream_name" {
  description = "Nombre del stream de métricas de CloudWatch"
  value       = aws_cloudwatch_metric_stream.main.name
}

output "metric_stream_arn" {
  description = "ARN del stream de métricas de CloudWatch"
  value       = aws_cloudwatch_metric_stream.main.arn
}
*/

output "metrics_bucket_name" {
  description = "Nombre del bucket de métricas"
  value       = var.create_metrics_bucket ? aws_s3_bucket.metrics[0].id : null
}

output "metrics_bucket_arn" {
  description = "ARN del bucket de métricas"
  value       = var.create_metrics_bucket ? aws_s3_bucket.metrics[0].arn : var.existing_metrics_bucket_arn
}

/*
output "firehose_stream_name" {
  description = "Nombre del stream de Kinesis Firehose"
  value       = aws_kinesis_firehose_delivery_stream.metrics.name
}

output "firehose_stream_arn" {
  description = "ARN del stream de Kinesis Firehose"
  value       = aws_kinesis_firehose_delivery_stream.metrics.arn
}
*/

/*
output "metric_stream_role_arn" {
  description = "ARN del rol IAM para el stream de métricas"
  value       = aws_iam_role.metric_stream.arn
}
*/

output "firehose_role_arn" {
  description = "ARN del rol IAM para Firehose"
  value       = aws_iam_role.firehose.arn
}

output "dashboard_name" {
  description = "Nombre del dashboard principal"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "lambda_errors_alarm_arn" {
  description = "ARN de la alarma de errores de Lambda"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "api_latency_alarm_arn" {
  description = "ARN de la alarma de latencia de API"
  value       = aws_cloudwatch_metric_alarm.api_latency.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${local.dashboard_name}"
}

output "alert_topic_arn" {
  description = "ARN del tema SNS para alertas"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones"
  value       = aws_sns_topic.alerts.arn
} 