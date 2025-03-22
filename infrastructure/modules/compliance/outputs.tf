output "config_bucket_name" {
  description = "Nombre del bucket S3 para AWS Config"
  value       = aws_s3_bucket.config.id
}

output "config_bucket_arn" {
  description = "ARN del bucket S3 para AWS Config"
  value       = aws_s3_bucket.config.arn
}

output "config_role_arn" {
  description = "The ARN of the AWS Config IAM role"
  value       = aws_iam_role.config.arn
}

output "config_recorder_id" {
  description = "ID del grabador de AWS Config"
  value       = aws_config_configuration_recorder.main.id
}

output "security_hub_arn" {
  description = "ARN de Security Hub"
  value       = try(aws_securityhub_account.main[0].id, null)
}

output "guardduty_detector_id" {
  description = "ID del detector de GuardDuty"
  value       = try(aws_guardduty_detector.main[0].id, null)
}

output "audit_assessment_id" {
  description = "ID de la evaluación de Audit Manager"
  value       = try(aws_auditmanager_assessment.main[0].id, null)
}

output "audit_role_arn" {
  description = "ARN del rol IAM para Audit Manager"
  value       = aws_iam_role.audit_role.arn
}

output "compliance_dashboard_name" {
  description = "Nombre del dashboard de compliance"
  value       = aws_cloudwatch_dashboard.compliance.dashboard_name
}

output "compliance_dashboard_url" {
  description = "URL del dashboard de compliance"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.compliance.dashboard_name}"
}

output "config_rules" {
  description = "Lista de reglas de AWS Config habilitadas"
  value = {
    s3_encryption = aws_config_config_rule.s3_bucket_encryption.id
    s3_versioning = aws_config_config_rule.s3_bucket_versioning.id
    rds_encryption = aws_config_config_rule.rds_encryption.id
    vpc_flow_logs = aws_config_config_rule.vpc_flow_logs.id
  }
}

output "security_standards" {
  description = "IDs de los estándares de seguridad habilitados"
  value = {
    cis = try(aws_securityhub_standards_subscription.cis[0].id, null)
    pci = try(aws_securityhub_standards_subscription.pci[0].id, null)
  }
}

output "compliance_event_rule_arn" {
  description = "ARN de la regla EventBridge para eventos de compliance"
  value       = aws_cloudwatch_event_rule.compliance_changes.arn
}

output "config_bucket_url" {
  description = "URL del bucket S3 para AWS Config"
  value       = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.config.id}?region=${var.region}"
}

output "security_hub_url" {
  description = "URL de Security Hub"
  value       = "https://${var.region}.console.aws.amazon.com/securityhub/home?region=${var.region}#/summary"
}

output "guardduty_url" {
  description = "URL de GuardDuty"
  value       = "https://${var.region}.console.aws.amazon.com/guardduty/home?region=${var.region}#/summary"
}

output "audit_manager_url" {
  description = "URL de Audit Manager"
  value       = "https://${var.region}.console.aws.amazon.com/auditmanager/home?region=${var.region}#/assessments"
} 