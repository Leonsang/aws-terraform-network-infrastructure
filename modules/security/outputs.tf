# Outputs para el módulo de seguridad

output "glue_role_arn" {
  description = "ARN del rol IAM para AWS Glue"
  value       = aws_iam_role.glue_role.arn
}

output "glue_role_name" {
  description = "Nombre del rol IAM para AWS Glue"
  value       = aws_iam_role.glue_role.name
}

output "lambda_role_arn" {
  description = "ARN del rol IAM para Lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Nombre del rol IAM para Lambda"
  value       = aws_iam_role.lambda_role.name
}

output "events_role_arn" {
  description = "ARN del rol IAM para CloudWatch Events"
  value       = aws_iam_role.events_role.arn
}

output "events_role_name" {
  description = "Nombre del rol IAM para CloudWatch Events"
  value       = aws_iam_role.events_role.name
}

output "redshift_role_arn" {
  description = "ARN del rol IAM para Redshift"
  value       = aws_iam_role.redshift_role.arn
}

output "redshift_role_name" {
  description = "Nombre del rol IAM para Redshift"
  value       = aws_iam_role.redshift_role.name
}

output "redshift_security_group_id" {
  description = "ID del grupo de seguridad para Redshift"
  value       = aws_security_group.redshift.id
}

output "quicksight_role_arn" {
  description = "ARN del rol IAM para QuickSight"
  value       = aws_iam_role.quicksight_role.arn
}

output "quicksight_role_name" {
  description = "Nombre del rol IAM para QuickSight"
  value       = aws_iam_role.quicksight_role.name
} 