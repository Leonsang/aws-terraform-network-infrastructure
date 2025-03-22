output "test_results_bucket_name" {
  description = "Nombre del bucket S3 para resultados de pruebas"
  value       = aws_s3_bucket.test_results.id
}

output "test_results_bucket_arn" {
  description = "ARN del bucket S3 para resultados de pruebas"
  value       = aws_s3_bucket.test_results.arn
}

output "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild para pruebas"
  value       = aws_codebuild_project.infrastructure_tests.name
}

output "codebuild_project_arn" {
  description = "ARN del proyecto CodeBuild para pruebas"
  value       = aws_codebuild_project.infrastructure_tests.arn
}

output "test_schedule_rule_arn" {
  description = "ARN de la regla EventBridge para ejecución programada"
  value       = aws_cloudwatch_event_rule.test_schedule.arn
}

output "test_notifications_topic_arn" {
  description = "ARN del topic SNS para notificaciones de pruebas"
  value       = aws_sns_topic.test_notifications.arn
}

output "test_dashboard_name" {
  description = "Nombre del dashboard de resultados de pruebas"
  value       = aws_cloudwatch_dashboard.test_results.dashboard_name
}

output "test_dashboard_url" {
  description = "URL del dashboard de resultados de pruebas"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.test_results.dashboard_name}"
}

output "test_results_url" {
  description = "URL del bucket S3 para ver resultados de pruebas"
  value       = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.test_results.id}?region=${var.region}"
}

output "codebuild_url" {
  description = "URL del proyecto CodeBuild"
  value       = "https://${var.region}.console.aws.amazon.com/codesuite/codebuild/${data.aws_caller_identity.current.account_id}/projects/${aws_codebuild_project.infrastructure_tests.name}"
}

output "test_security_group_id" {
  description = "ID del grupo de seguridad para pruebas"
  value       = aws_security_group.codebuild.id
}

output "test_role_arn" {
  description = "ARN del rol IAM para pruebas"
  value       = aws_iam_role.codebuild_role.arn
}

output "test_alarm_arn" {
  description = "ARN de la alarma CloudWatch para fallos en pruebas"
  value       = aws_cloudwatch_metric_alarm.test_failures.arn
}

output "test_log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch para pruebas"
  value       = "/aws/codebuild/${var.project_name}-${var.environment}-infra-tests"
}

output "test_log_group_url" {
  description = "URL del grupo de logs de CloudWatch para pruebas"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#logsV2:log-groups/log-group/${replace("/aws/codebuild/${var.project_name}-${var.environment}-infra-tests", "/", "$252F")}"
}

output "test_schedule_expression" {
  description = "Expresión cron para la ejecución programada de pruebas"
  value       = var.test_schedule
}

output "test_notification_emails" {
  description = "Lista de correos electrónicos configurados para notificaciones"
  value       = var.test_notification_emails
}

output "test_configuration" {
  description = "Configuración actual de las pruebas"
  value = {
    compute_type            = var.test_compute_type
    timeout                 = var.test_timeout
    parallelization        = var.test_parallelization
    retry_count            = var.test_retry_count
    failure_threshold      = var.test_failure_threshold
    coverage_threshold     = var.test_coverage_threshold
    reports_retention_days = var.test_reports_retention_days
  }
}

output "enabled_test_types" {
  description = "Tipos de pruebas habilitados"
  value = {
    vulnerability_scanning = var.enable_vulnerability_scanning
    static_analysis       = var.enable_static_analysis
    integration_tests     = var.enable_integration_tests
    load_tests           = var.enable_load_tests
    security_tests       = var.enable_security_tests
    performance_tests    = var.enable_performance_tests
  }
} 