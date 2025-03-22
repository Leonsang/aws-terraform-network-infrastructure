output "log_bucket_name" {
  description = "Nombre del bucket S3 para logs"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  description = "ARN del bucket S3 para logs"
  value       = aws_s3_bucket.logs.arn
}

output "app_log_group_name" {
  description = "Nombre del grupo de logs de aplicación"
  value       = aws_cloudwatch_log_group.app.name
}

output "app_log_group_arn" {
  description = "ARN del grupo de logs de aplicación"
  value       = aws_cloudwatch_log_group.app.arn
}

output "system_log_group_name" {
  description = "Nombre del grupo de logs de sistema"
  value       = aws_cloudwatch_log_group.system.name
}

output "system_log_group_arn" {
  description = "ARN del grupo de logs de sistema"
  value       = aws_cloudwatch_log_group.system.arn
}

output "audit_log_group_name" {
  description = "Nombre del grupo de logs de auditoría"
  value       = aws_cloudwatch_log_group.audit.name
}

output "audit_log_group_arn" {
  description = "ARN del grupo de logs de auditoría"
  value       = aws_cloudwatch_log_group.audit.arn
}

output "firehose_stream_name" {
  description = "Nombre del stream de Kinesis Firehose"
  value       = aws_kinesis_firehose_delivery_stream.logs_to_s3.name
}

output "firehose_stream_arn" {
  description = "ARN del stream de Kinesis Firehose"
  value       = aws_kinesis_firehose_delivery_stream.logs_to_s3.arn
}

output "cloudwatch_to_firehose_role_arn" {
  description = "ARN del rol IAM para CloudWatch a Firehose"
  value       = aws_iam_role.cloudwatch_to_firehose.arn
}

output "firehose_role_arn" {
  description = "ARN del rol IAM para Firehose"
  value       = aws_iam_role.firehose.arn
}

output "error_alarm_arn" {
  description = "ARN de la alarma de errores"
  value       = aws_cloudwatch_metric_alarm.error_logs.arn
}

output "dashboard_name" {
  description = "Nombre del dashboard de logs"
  value       = aws_cloudwatch_dashboard.logs.dashboard_name
}

output "log_group_name" {
  description = "Nombre del grupo de logs principal"
  value       = aws_cloudwatch_log_group.main.name
}

output "log_group_arn" {
  description = "ARN del grupo de logs principal"
  value       = aws_cloudwatch_log_group.main.arn
}

output "log_metric_alarm_arn" {
  description = "ARN de la alarma de métricas de logs"
  value       = aws_cloudwatch_metric_alarm.log_delivery_errors.arn
}

output "log_subscription_filter_name" {
  description = "Nombre del filtro de suscripción de logs"
  value       = aws_cloudwatch_log_subscription_filter.logs_to_firehose.name
}

output "firehose_log_group_name" {
  description = "Nombre del grupo de logs de Firehose"
  value       = aws_cloudwatch_log_group.firehose.name
}

output "firehose_log_group_arn" {
  description = "ARN del grupo de logs de Firehose"
  value       = aws_cloudwatch_log_group.firehose.arn
} 