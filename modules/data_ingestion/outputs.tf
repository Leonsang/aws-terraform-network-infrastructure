# Outputs del módulo de ingesta de datos

output "lambda_function_name" {
  description = "Nombre de la función Lambda de descarga de datos"
  value       = aws_lambda_function.kaggle_downloader.function_name
}

output "lambda_function_arn" {
  description = "ARN de la función Lambda de descarga de datos"
  value       = aws_lambda_function.kaggle_downloader.arn
}

output "lambda_role_arn" {
  description = "ARN del rol IAM de la función Lambda"
  value       = var.lambda_role_arn
}

output "event_rule_arn" {
  description = "ARN de la regla de EventBridge para la programación de descarga"
  value       = aws_cloudwatch_event_rule.download_schedule.arn
}

output "kaggle_layer_arn" {
  description = "ARN de la capa Lambda con la biblioteca Kaggle"
  value       = aws_lambda_layer_version.kaggle_layer.arn
}

output "kaggle_layer_name" {
  description = "Nombre de la capa Lambda con la biblioteca Kaggle"
  value       = aws_lambda_layer_version.kaggle_layer.layer_name
}

output "lambda_log_group_name" {
  description = "Nombre del grupo de logs de la función Lambda"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "lambda_log_group_arn" {
  description = "ARN del grupo de logs de la función Lambda"
  value       = aws_cloudwatch_log_group.lambda_log_group.arn
} 