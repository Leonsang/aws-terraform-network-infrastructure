output "workgroup_name" {
  description = "Nombre del workgroup de Athena"
  value       = aws_athena_workgroup.fraud_detection.name
}

output "database_name" {
  description = "Nombre de la base de datos de Athena"
  value       = aws_athena_database.fraud_detection.name
}

output "athena_role_arn" {
  description = "ARN del rol IAM de Athena"
  value       = aws_iam_role.athena_role.arn
}

output "transactions_table" {
  description = "Nombre de la tabla de transacciones"
  value       = "transactions"
}

output "merchants_table" {
  description = "Nombre de la tabla de comerciantes"
  value       = "merchants"
}

output "fraud_analysis_table" {
  description = "Nombre de la tabla de análisis de fraude"
  value       = "fraud_analysis"
}

output "fraud_metrics_view" {
  description = "Nombre de la vista de métricas de fraude"
  value       = "fraud_metrics"
} 