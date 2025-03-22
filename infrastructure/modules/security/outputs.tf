output "organization_id" {
  description = "ID de la organización de AWS"
  value       = var.create_organization ? aws_organizations_organization.main[0].id : null
}

output "organization_arn" {
  description = "ARN de la organización de AWS"
  value       = var.create_organization ? aws_organizations_organization.main[0].arn : null
}

output "scp_id" {
  description = "ID de la Service Control Policy"
  value       = var.create_organization ? aws_organizations_policy.scp[0].id : null
}

output "scp_arn" {
  description = "ARN de la Service Control Policy"
  value       = var.create_organization ? aws_organizations_policy.scp[0].arn : null
}

output "config_recorder_id" {
  description = "ID del recorder de AWS Config"
  value       = aws_config_configuration_recorder.main.id
}

output "config_bucket_name" {
  description = "Nombre del bucket S3 para AWS Config"
  value       = aws_s3_bucket.config.id
}

output "config_bucket_arn" {
  description = "ARN del bucket S3 para AWS Config"
  value       = aws_s3_bucket.config.arn
}

output "config_role_arn" {
  description = "ARN del rol de AWS Config"
  value       = aws_iam_role.config.arn
}

output "security_hub_id" {
  description = "ID de Security Hub"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
}

/*output "aws_foundational_standards_arn" {
  description = "The ARN of the AWS Foundational Security Best Practices standard"
  value       = var.enable_security_hub ? aws_securityhub_standards_subscription.aws_foundational[0].id : null
}*/

output "security_findings_alarm_arn" {
  description = "ARN de la alarma de hallazgos de seguridad"
  value       = var.enable_security_hub ? aws_cloudwatch_metric_alarm.security_hub_findings[0].arn : null
}

output "security_dashboard_name" {
  description = "Nombre del dashboard de seguridad"
  value       = aws_cloudwatch_dashboard.security.dashboard_name
}

output "lambda_role_arn" {
  description = "ARN del rol IAM para funciones Lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "glue_role_arn" {
  description = "ARN del rol IAM para trabajos Glue"
  value       = aws_iam_role.glue_role.arn
}

output "redshift_role_arn" {
  description = "ARN del rol IAM para Redshift"
  value       = aws_iam_role.redshift.arn
}

output "kms_key_arn" {
  description = "ARN de la clave KMS"
  value       = aws_kms_key.main.arn
} 