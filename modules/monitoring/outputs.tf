# Outputs para el módulo de monitoreo

output "sns_topic_arn" {
  description = "ARN del tema SNS para alertas"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Nombre del tema SNS para alertas"
  value       = aws_sns_topic.alerts.name
}

output "cloudwatch_dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "cloudwatch_alarms" {
  description = "Lista de alarmas de CloudWatch"
  value = {
    glue_job_failure           = aws_cloudwatch_metric_alarm.glue_job_failure.arn
    lambda_data_quality_errors = aws_cloudwatch_metric_alarm.lambda_data_quality_errors.arn
    lambda_realtime_fraud_errors = aws_cloudwatch_metric_alarm.lambda_realtime_fraud_errors.arn
    kinesis_iterator_age       = aws_cloudwatch_metric_alarm.kinesis_iterator_age.arn
  }
} 