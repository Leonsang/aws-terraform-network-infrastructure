output "documentation_bucket_name" {
  description = "Nombre del bucket S3 para documentación"
  value       = aws_s3_bucket.documentation.id
}

output "documentation_bucket_arn" {
  description = "ARN del bucket S3 para documentación"
  value       = aws_s3_bucket.documentation.arn
}

output "documentation_website_endpoint" {
  description = "Endpoint del sitio web de documentación"
  value       = aws_s3_bucket_website_configuration.documentation.website_endpoint
}

output "documentation_website_domain" {
  description = "Dominio del sitio web de documentación"
  value       = aws_s3_bucket_website_configuration.documentation.website_domain
}

output "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild para documentación"
  value       = aws_codebuild_project.documentation.name
}

output "codebuild_project_arn" {
  description = "ARN del proyecto CodeBuild para documentación"
  value       = aws_codebuild_project.documentation.arn
}

output "docs_update_schedule" {
  description = "Expresión cron para actualización de documentación"
  value       = aws_cloudwatch_event_rule.docs_update.schedule_expression
}

output "docs_notification_topic_arn" {
  description = "ARN del topic SNS para notificaciones de documentación"
  value       = aws_sns_topic.docs_notifications.arn
}

output "docs_dashboard_name" {
  description = "Nombre del dashboard de documentación"
  value       = aws_cloudwatch_dashboard.documentation.dashboard_name
}

output "docs_dashboard_url" {
  description = "URL del dashboard de documentación"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.documentation.dashboard_name}"
}

output "docs_alarm_arn" {
  description = "ARN de la alarma CloudWatch para fallos en documentación"
  value       = aws_cloudwatch_metric_alarm.docs_failures.arn
}

output "docs_log_group_name" {
  description = "Nombre del grupo de logs de CloudWatch para documentación"
  value       = "/aws/codebuild/${var.project_name}-${var.environment}-docs"
}

output "docs_log_group_url" {
  description = "URL del grupo de logs de CloudWatch para documentación"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#logsV2:log-groups/log-group/${replace("/aws/codebuild/${var.project_name}-${var.environment}-docs", "/", "$252F")}"
}

output "docs_role_arn" {
  description = "ARN del rol IAM para documentación"
  value       = aws_iam_role.codebuild_role.arn
}

output "docs_configuration" {
  description = "Configuración actual de la documentación"
  value = {
    format              = var.docs_format
    template            = var.docs_template
    language           = var.docs_language
    enable_versioning  = var.enable_versioning
    enable_search      = var.enable_search
    enable_feedback    = var.enable_feedback
    enable_diagrams    = var.enable_diagrams
    diagram_type       = var.diagram_type
    enable_pdf_export  = var.enable_pdf_export
    enable_changelog   = var.enable_changelog
  }
}

output "enabled_documentation_types" {
  description = "Tipos de documentación habilitados"
  value = {
    api             = var.enable_api_documentation
    infrastructure = var.enable_infrastructure_documentation
    code           = var.enable_code_documentation
  }
}

output "docs_build_info" {
  description = "Información de construcción de documentación"
  value = {
    compute_type        = var.docs_compute_type
    build_timeout       = var.docs_build_timeout
    concurrent_builds   = var.docs_concurrent_builds
    retention_days     = var.docs_retention_days
  }
} 