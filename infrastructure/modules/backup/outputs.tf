output "backup_vault_arn" {
  description = "ARN del vault principal de respaldos"
  value       = aws_backup_vault.main.arn
}

output "backup_vault_name" {
  description = "Nombre del vault principal de respaldos"
  value       = aws_backup_vault.main.name
}

output "dr_vault_arn" {
  description = "ARN del vault de disaster recovery"
  value       = aws_backup_vault.dr.arn
}

output "dr_vault_name" {
  description = "Nombre del vault de disaster recovery"
  value       = aws_backup_vault.dr.name
}

output "backup_plan_id" {
  description = "ID del plan de respaldo"
  value       = aws_backup_plan.main.id
}

output "backup_plan_arn" {
  description = "ARN del plan de respaldo"
  value       = aws_backup_plan.main.arn
}

output "backup_role_arn" {
  description = "ARN del rol IAM para respaldos"
  value       = aws_iam_role.backup.arn
}

output "backup_selection_id" {
  description = "ID de la selección de recursos para respaldo"
  value       = aws_backup_selection.main.id
}

output "sns_topic_arn" {
  description = "ARN del topic SNS para notificaciones de respaldo"
  value       = aws_sns_topic.backup_notifications.arn
}

output "cloudwatch_event_rule_arn" {
  description = "ARN de la regla de CloudWatch Events para respaldos"
  value       = aws_cloudwatch_event_rule.backup_events.arn
} 